package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
)

func writeJSON(w http.ResponseWriter, obj interface{}) {
	json, err := json.MarshalIndent(obj, "", "    ")
	if err != nil {
		log.Printf("writeJSON error: %v", err)
		return
	}

	w.Write(json)
}

func enableCors(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
}

// printPostForm prints the pairs of keys and values from a request's form
func printPostForm(r *http.Request) {
	longest := 0
	for key, _ := range r.PostForm {
		if len(key) > longest {
			longest = len(key)
		}
	}

	fmt.Printf("\n\033[95m\033[4mForm: %s\033[0m\n", r.URL.String())
	for key, values := range r.PostForm {
		strVals := ""
		if len(values) > 1 {
			strVals = "[" + strings.Join(values, ",") + "]"
		} else {
			strVals = values[0]
		}
		fmt.Printf("\033[36m%-*s \033[0m..... %s\n", longest, key, strVals)
	}
}

func findGame(games []Game, id int) (Game, error) {
	for _, g := range games {
		if g.ID == id {
			return g, nil
		}
	}
	return Game{}, fmt.Errorf("Could not find game %d", id)
}

func getScoreMap(holes int, scores []GameScore) map[int]map[int]int {
	scoreMap := make(map[int]map[int]int)

	// Initialize holes with empty map
	for hole := 1; hole <= holes; hole++ {
		scoreMap[hole] = make(map[int]int)
	}

	// Populate maps
	for _, score := range scores {
		scoreMap[score.HoleNum][score.PlayerID] = score.Score
	}

	return scoreMap
}

func getScoreArray(holes int, scores []GameScore) [][]GameScore {
	scoreMap := make([][]GameScore, holes)

	// Populate maps
	for _, score := range scores {
		scoreMap[score.HoleNum-1] = append(scoreMap[score.HoleNum-1], score)
	}

	return scoreMap
}
