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
// order by score asc limit 1;

var queries []LeaderboardQuery = []LeaderboardQuery{
	{
		Title: "Games Played",
		Query: `select p.name,count(gp.player_id) as value from game_players gp
		left join players p on p.id = gp.player_id
		group by gp.player_id;`,
	},
}

func ListStatistics(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	var results []LeaderboardResult

	for _, query := range queries {
		var result LeaderboardResult
		result.Title = query.Title
		db.Raw(query.Query).Scan(&result.Entries)
	}

	writeJSON(w, results)
}
