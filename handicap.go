package main

import (
	"fmt"
	"log"
	"sort"
)

func calculateHandicaps() ([]HandicapPlayer, error) {
	var players []HandicapPlayer
	if err := db.Find(&players).Error; err != nil {
		log.Print(err)
		return nil, err
	}

	var scores []Handicap
	if err := db.Raw(`select * from total_scores s
		left join games g on g.id=s.game_id
		left join courses c on c.id=g.course_id
		where g.hole_count=9 AND TIMESTAMPDIFF(HOUR, g.date, g.end_time) != 8
		order by g.date desc`).Scan(&scores).Error; err != nil {
		log.Print(err)
		return nil, err
	}

	rating := scores[0].Rating / 2
	slope := scores[0].Slope

	// Add the latest scores to the player objects
	for _, score := range scores {

		// Find the player to give the score to
		for i, player := range players {
			if player.ID == score.PlayerID {
				// Can't add score if there's too many
				if len(players[i].LatestScores) > 20 {
					break
				}

				players[i].LatestScores = append(players[i].LatestScores, score.TotalScore)
				break
			}
		}
	}

	// Calculate differentials
	for i, player := range players {
		for _, score := range player.LatestScores {
			players[i].Differentials = append(players[i].Differentials, (float64(score)-rating)*(113/slope))
		}

		// Sort differentials lowest to highest
		sort.Float64s(players[i].Differentials)

		// Average the best 5
		var total float64 = 0
		for _, diff := range players[i].Differentials[:5] {
			total += diff
		}

		// Calculate the handicap index
		players[i].Index = (total / 5) * 0.96

		// Truncate index
		players[i].Index = float64(int(players[i].Index*10)) / 10
	}

	return players, nil
}

func getHandicapLeaderboard() ([]LeaderboardEntry, error) {
	players, err := calculateHandicaps()
	if err != nil {
		return nil, err
	}

	var entries []LeaderboardEntry

	// Sort the players by lowest handicap
	sort.Slice(players, func(i, j int) bool {
		return players[i].Index < players[j].Index
	})

	// Add handicaps to leaderboard entry
	for i, player := range players {
		entries = append(entries, LeaderboardEntry{
			Name:     player.Name,
			Value:    fmt.Sprintf("%.1f", players[i].Index),
			GameList: make([]int, 0),
		})
	}

	return entries, nil
}
