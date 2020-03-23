package main

import (
	"log"
	"net/http"
	"os"

	"github.com/jinzhu/gorm"
)

var db *gorm.DB

func initRoutes() {
	// Scorecards
	http.HandleFunc("/listentries", ListEntries)
	http.HandleFunc("/createnew", CreateGameNew)
	http.HandleFunc("/getgamenew", GetGameNew)
	http.HandleFunc("/setscorenew", SetScoreNew)
	http.HandleFunc("/deletegame", DeleteGame)

	// Leaderboards
	http.HandleFunc("/leaderboard", ListStatistics)
}

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