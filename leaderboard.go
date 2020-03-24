package main

import (
	"net/http"
)

// Get final score for each player of game with id XX
//
// select player_id, sum(score)
// from game_scores where game_id=XX
// group by player_id

// Get winner of a given game with id XX
//
// select player_id, sum(score) as score
// from game_scores where game_id=XX
// group by player_id
// order by score asc limit 1

var queries []LeaderboardQuery = []LeaderboardQuery{
	{
		Title: "Most Games Played",
		Query: `select p.name,count(gp.player_id) as value from game_players gp
					left join players p on p.id = gp.player_id
					group by gp.player_id
					order by count(gp.player_id) desc`,
	},
	{
		Title: "Lowest Score",
		Query: `select p.name, min(s.total_score) as value from
					(
						select player_id, game_id, sum(score) as total_score from game_scores group by game_id, player_id
					) s
					left join players p on p.id=s.player_id
					group by s.player_id
					order by value`,
	},
	{
		Title: "Most Pars",
		Query: `select p.name,count(gs.player_id) as value from game_scores gs
					left join games g on g.id = gs.game_id
					left join course_pars cp on cp.course_id = g.course_id and IF(g.front,gs.hole_num,gs.hole_num+9) = cp.hole_num
					left join players p on p.id = gs.player_id
					where gs.score=cp.par
					group by gs.player_id
					order by value desc`,
	},
	{
		Title: "Most Birdies",
		Query: `select p.name,count(gs.player_id) as value from game_scores gs
					left join games g on g.id = gs.game_id
					left join course_pars cp on cp.course_id = g.course_id and IF(g.front,gs.hole_num,gs.hole_num+9) = cp.hole_num
					left join players p on p.id = gs.player_id
					where gs.score=cp.par-1
					group by gs.player_id
					order by value desc`,
	},
	{
		Title: "Most Eagles",
		Query: `select p.name,count(gs.player_id) as value from game_scores gs
					left join games g on g.id = gs.game_id
					left join course_pars cp on cp.course_id = g.course_id and IF(g.front,gs.hole_num,gs.hole_num+9) = cp.hole_num
					left join players p on p.id = gs.player_id
					where gs.score=cp.par-2
					group by gs.player_id
					order by value desc`,
	},
}

func ListStatistics(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	for i, query := range queries {
		db.Raw(query.Query).Scan(&queries[i].Entries)
	}

	writeJSON(w, queries)
}
