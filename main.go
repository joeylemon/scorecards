package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/jinzhu/gorm"
)

var db *gorm.DB

func main() {
	// Grab mysql connection information
	constr := os.Getenv("MYSQL_CONNECTION")
	if constr == "" {
		log.Fatalf("Missing mysql connection string")
	}

	// Open mysql connection
	var err error
	db, err = gorm.Open("mysql", constr+"?parseTime=true")
	if err != nil {
		log.Fatalf("Cannot open mysql connection")
	}
	defer db.Close()
	db.LogMode(true)

	initRoutes()

	log.Println("Listening on :8000")
	err = http.ListenAndServe(":8000", nil)
	if err != nil {
		log.Printf("Couldn't start http server: %v", err)
	}
}

func writeJSON(w http.ResponseWriter, obj interface{}) {
	json, err := json.Marshal(obj)
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