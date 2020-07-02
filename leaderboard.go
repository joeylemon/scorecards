package main

import (
	"net/http"
	"strconv"
	"strings"
)

var queries []LeaderboardQuery = []LeaderboardQuery{
	{
		Title: "Most Wins",
		Query: `select p.name, count(s1.player_id) as value, 
					GROUP_CONCAT(s1.game_id SEPARATOR ', ') as games from total_scores s1
					join (
						select game_id, min(total_score) as winner_score from total_scores 
						left join games g on g.id=game_id
						where TIMESTAMPDIFF(HOUR, g.date, g.end_time) != 8
						group by game_id
					) s2
					on s1.total_score=s2.winner_score and s1.game_id=s2.game_id
					left join players p on p.id=s1.player_id
					group by s1.player_id
					order by value desc`,
	},
	{
		Title: "Highest Win Rate",
		Query: `select p.name, round(count(s1.player_id)/(select count(player_id) from game_players 
					where player_id=s1.player_id), 2) as value, GROUP_CONCAT(s1.game_id SEPARATOR ', ') as games from total_scores s1
					join (
						select game_id, min(total_score) as winner_score from total_scores 
						left join games g on g.id=game_id
						where TIMESTAMPDIFF(HOUR, g.date, g.end_time) != 8
						group by game_id
					) s2
					on s1.total_score=s2.winner_score and s1.game_id=s2.game_id
					left join players p on p.id=s1.player_id
					group by s1.player_id
					order by value desc`,
	},
	{
		Title: "Most Games Played",
		Query: `select p.name,count(gp.player_id) as value, 
					GROUP_CONCAT(gp.game_id SEPARATOR ', ') as games from game_players gp
					left join players p on p.id = gp.player_id
					group by gp.player_id
					order by count(gp.player_id) desc`,
	},
	{
		Title: "Lowest Score",
		Query: `select p.name, s2.lowest_score as value, 
					GROUP_CONCAT(s1.game_id SEPARATOR ', ') as games from total_scores s1
					join (
						select player_id, min(total_score) as lowest_score from total_scores 
						left join games g on g.id=game_id
						where TIMESTAMPDIFF(HOUR, g.date, g.end_time) != 8
						group by player_id
					) s2
					on s1.total_score=s2.lowest_score and s1.player_id=s2.player_id
					left join players p on p.id=s1.player_id
					group by s1.player_id
					order by value asc`,
	},
	{
		Title: "Lowest Handicap",
		Query: `select p.name, truncate((((AVG(s.total_score)*2 - c.rating)*113)/c.slope)*0.96, 1) 
					as value, '' as games
					from total_scores s
					left join players p on p.id=s.player_id
					left join games g on g.id=s.game_id
					left join courses c on c.id=g.course_id
					where g.hole_count=9
					group by s.player_id
					order by value`,
	},
	{
		Title: "Highest Par Rate",
		Query: `select p.name,round(count(gs.player_id)/
					(select count(player_id) from game_scores where player_id=gs.player_id), 2)
					as value, GROUP_CONCAT(g.id SEPARATOR ', ') as games from game_scores gs
					left join games g on g.id = gs.game_id
					left join course_pars cp on cp.course_id = g.course_id and IF(g.front,gs.hole_num,gs.hole_num+9) = cp.hole_num
					left join players p on p.id = gs.player_id
					where gs.score<=cp.par
					group by gs.player_id
					order by value desc`,
	},
	{
		Title: "Most Pars",
		Query: `select p.name,count(gs.player_id) as value, 
					GROUP_CONCAT(g.id SEPARATOR ', ') as games from game_scores gs
					left join games g on g.id = gs.game_id
					left join course_pars cp on cp.course_id = g.course_id and IF(g.front,gs.hole_num,gs.hole_num+9) = cp.hole_num
					left join players p on p.id = gs.player_id
					where gs.score=cp.par
					group by gs.player_id
					order by value desc`,
	},
	{
		Title: "Most Birdies",
		Query: `select p.name,count(gs.player_id) as value, 
					GROUP_CONCAT(g.id SEPARATOR ', ') as games from game_scores gs
					left join games g on g.id = gs.game_id
					left join course_pars cp on cp.course_id = g.course_id and IF(g.front,gs.hole_num,gs.hole_num+9) = cp.hole_num
					left join players p on p.id = gs.player_id
					where gs.score=cp.par-1
					group by gs.player_id
					order by value desc`,
	},
	{
		Title: "Easiest Hole",
		Query: `select gs.hole_num as name, 
					concat('+', round(avg(gs.score) - cp.par, 2)) as value, 
					null as games from game_scores gs 
					left join games g on g.id=gs.game_id
					left join course_pars cp on cp.hole_num=gs.hole_num and cp.course_id=g.course_id
					where g.course_id=1 and g.hole_count=9
					group by gs.hole_num
					order by value`,
	},
	{
		Title: "Total Time Played",
		Query: `select c.name, 
					concat(round(sum(UNIX_TIMESTAMP(g.end_time)-UNIX_TIMESTAMP(g.date))/3600, 1), ' hours') as value,
					GROUP_CONCAT(g.id SEPARATOR ', ') as games from games g
					left join courses c on c.id=g.course_id
					group by g.course_id`,
	},
	{
		Title: "Average Game Length",
		Query: `select c.name, 
					time_format(sec_to_time(avg(time_to_sec(timediff(g.end_time, g.date)))), '%lh %im') as value,
					group_concat(g.id separator ', ') as games
					from games g
					left join courses c on c.id=g.course_id
					where g.hole_count=9
					group by g.course_id`,
	},
}

// ListStatistics lists the statistics to be ranked in the leaderboards
func ListStatistics(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	for i, query := range queries {
		if strings.Contains(query.Title, "Handicap") {
			var err error
			queries[i].Entries, err = getHandicapLeaderboard()
			if err != nil {
				handleError(err)
			}

			continue
		}

		db.Raw(query.Query).Scan(&queries[i].Entries)

		// Scan game string into list of ids
		for j, entry := range queries[i].Entries {
			games := strings.Split(entry.Games, ", ")

			if entry.Games == "" {
				queries[i].Entries[j].GameList = make([]int, 0)
				continue
			}

			for _, game := range games {
				num, err := strconv.Atoi(game)
				if err != nil {
					continue
				}

				queries[i].Entries[j].GameList = append(queries[i].Entries[j].GameList, num)
			}
		}
	}

	writeJSON(w, queries)
}
