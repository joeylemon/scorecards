package main

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

func initRoutes() {
	// Set up api handlers
	http.HandleFunc("/listentries", ListEntries)
	http.HandleFunc("/createnew", CreateGameNew)
	http.HandleFunc("/getgamenew", GetGameNew)
	http.HandleFunc("/setscorenew", SetScoreNew)
	http.HandleFunc("/deletegame", DeleteGame)
}

func ListEntries(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	var games []Game
	if err := db.Preload("Course").Order("id desc").Find(&games).Error; err != nil {
		log.Printf("ListEntries error: %v", err)
		return
	}

	var gamePlayers []GamePlayer
	if err := db.Preload("Player").Find(&gamePlayers).Error; err != nil {
		log.Printf("ListEntries error: %v", err)
		return
	}

	scoreSums := make(map[int]int)
	var gameScores []GameScore
	if err := db.Find(&gameScores).Error; err != nil {
		log.Printf("ListEntries error: %v", err)
		return
	}

	for i, game := range games {
		games[i].DateString = game.Date.Format("Jan 2 2006")

		durationTime := time.Time{}.Add(game.EndTime.Sub(game.Date))
		games[i].DurationString = fmt.Sprintf("%dh %dm", durationTime.Hour(), durationTime.Minute())

		// Sum the player's scores
		totalIncompletePlayers := 0
		for _, score := range gameScores {
			if score.GameID == game.ID {
				scoreSums[score.PlayerID] += score.Score
				if game.isLastHole(score.HoleNum) && score.Score == 0 {
					totalIncompletePlayers++
				}
			}
		}

		// Find the lowest score
		lowestScore := 200
		for _, score := range gameScores {
			sum := scoreSums[score.PlayerID]
			if score.GameID == game.ID && sum < lowestScore {
				// Don't count if a player quits at 9 holes out of 18
				if game.HoleCount == 18 && sum > 30 && sum < 65 {
					continue
				}
				lowestScore = sum
			}
		}

		// Add each player to single string, and set game's winner flag
		winnerCount := 0
		for _, player := range gamePlayers {
			if player.GameID == game.ID {
				games[i].Players = append(games[i].Players, player.Player.Name)
				if scoreSums[player.PlayerID] == lowestScore {
					games[i].Winner = strings.ToLower(string(player.Player.Name[0]))
					winnerCount++
				}
			}
		}

		if winnerCount > 1 || winnerCount == 0 {
			// More than one winner means there's a tie
			games[i].Winner = "t"
		}

		if totalIncompletePlayers >= len(games[i].Players)/2+1 {
			// If a majority of players didn't finish, game is incomplete
			games[i].Winner = "i"
			games[i].DurationString = "In progress"
		}

		games[i].People = strings.Join(games[i].Players, ", ")
		scoreSums = make(map[int]int)
	}

	writeJSON(w, games)
}

func CreateGameNew(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		log.Printf("CreateGame error: %v", err)
		return
	}
	printPostForm(r)

	if len(r.Form.Get("players")) == 0 {
		return
	}

	lat, err := strconv.ParseFloat(r.Form.Get("lat"), 64)
	if err != nil {
		lat = 0.0
	}

	lon, err := strconv.ParseFloat(r.Form.Get("lon"), 64)
	if err != nil {
		lon = 0.0
	}

	players := strings.Split(r.Form.Get("players"), ",")
	holes, _ := strconv.Atoi(r.Form.Get("holes"))
	front := r.Form.Get("front") == "true"

	// Front will always be true if playing 18 holes
	if holes == 18 {
		front = true
	}

	// Create the game
	var game Game
	game.CourseID = getClosestCourse(lat, lon).ID
	game.Front = front
	game.HoleCount = holes
	game.Date = time.Now().UTC()
	game.EndTime = time.Now().Add(time.Hour * 8).UTC()
	if err = db.Create(&game).Error; err != nil {
		log.Printf("CreateGame error: %v", err)
	}

	// Associate players with the game
	for _, playerID := range players {
		var gamePlayer GamePlayer
		gamePlayer.GameID = game.ID
		gamePlayer.PlayerID, _ = strconv.Atoi(playerID)
		if err = db.Create(&gamePlayer).Error; err != nil {
			log.Printf("CreateGame error: %v", err)
		}

		// Create empty scores
		for i := 1; i <= holes; i++ {
			var gameScore GameScore
			gameScore.GameID = game.ID
			gameScore.PlayerID, _ = strconv.Atoi(playerID)
			gameScore.HoleNum = i
			gameScore.Score = 0
			if err = db.Create(&gameScore).Error; err != nil {
				log.Printf("CreateGame error: %v", err)
			}
		}
	}
}

func GetGameNew(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		log.Printf("GetGame error: %v", err)
		return
	}
	printPostForm(r)

	id := r.Form.Get("id")

	var game Game
	if err := db.Where("id = ?", id).Find(&game).Error; err != nil {
		log.Printf("GetGame error: %v", err)
	}

	// Get a list of hole pars
	var pars []int
	var coursePars []CoursePar
	if err := db.Where("course_id = ?", game.CourseID).Order("hole_num asc").Find(&coursePars).Error; err != nil {
		log.Printf("GetGame error: %v", err)
	}

	if len(coursePars) > 0 {
		for _, par := range coursePars {
			// pars[hole-1] = score
			pars = append(pars, par.Par)
		}
	} else {
		// If the course has no associated pars, assume par 3
		pars = []int{3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}
	}

	var players []Player
	if err = db.Raw("SELECT p.* FROM game_players gp INNER JOIN players p ON p.id=gp.player_id WHERE gp.game_id = ?", id).Find(&players).Error; err != nil {
		log.Printf("GetGame error: %v", err)
	}

	var people []string
	for _, player := range players {
		people = append(people, player.Name)
	}
	peopleString := strings.Join(people, ", ")

	scoreSums := make(map[int]int)
	var scores []GameScore
	if err = db.Where("game_id = ?", id).Find(&scores).Error; err != nil {
		log.Printf("GetGame error: %v", err)
	}

	// Sum the player's scores
	for _, score := range scores {
		scoreSums[score.PlayerID] += score.Score
	}

	lowestScore := 200
	for _, score := range scores {
		if scoreSums[score.PlayerID] < lowestScore {
			// Don't count if a player quits at 9 holes out of 18
			if game.HoleCount == 18 && scoreSums[score.PlayerID] < 65 {
				continue
			}
			lowestScore = scoreSums[score.PlayerID]
		}
	}

	h := struct {
		ID          int
		People      string
		Course      Course
		DateString  string
		Front       bool
		Holes       int
		LowestScore int
		Players     []Player
		Scores      [][]GameScore
		Pars        []int
	}{
		ID:          game.ID,
		People:      peopleString,
		Course:      game.Course,
		DateString:  game.Date.Format("Jan 2 2006"),
		Front:       game.Front,
		Holes:       game.HoleCount,
		LowestScore: lowestScore,
		Players:     players,
		Scores:      getScoreArray(game.HoleCount, scores),
		Pars:        pars,
	}

	writeJSON(w, h)
}

func SetScoreNew(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		log.Printf("SetScore error: %v", err)
		return
	}
	printPostForm(r)

	gameID := r.Form.Get("gameID")

	// Get game from db
	var game Game
	if err := db.Where("id = ?", gameID).Find(&game).Error; err != nil {
		log.Printf("SetScoreNew error: %v", err)
	}

	// Make sure game isn't over a day old
	if time.Now().UTC().Sub(game.EndTime).Hours() > 1 {
		log.Print("SetScoreNew error: cannot change game score after 1 hour of ending")
		return
	}

	holes, _ := strconv.Atoi(r.Form.Get("holes"))
	players := strings.Split(r.Form.Get("players"), ",")

	completedGame := false

	var values []string
	for hole := 1; hole <= holes; hole++ {
		for _, player := range players {
			score := r.Form.Get(fmt.Sprintf("score[%d][%s]", hole, player))
			log.Printf("score[%d][%s]=%s", hole, player, score)
			values = append(values, fmt.Sprintf("(%s, %s, %d, %s)", gameID, player, hole, score))

			if game.isLastHole(hole) && score != "0" {
				completedGame = true
			}
		}
	}

	if completedGame {
		if err := db.Model(Game{}).Where("id = ?", gameID).Update("end_time", time.Now().UTC()).Error; err != nil {
			log.Printf("SetScoreNew error: %v", err)
		}
	}

	if err := db.Delete(GameScore{}, "game_id = ?", gameID).Error; err != nil {
		log.Printf("SetScoreNew error: %v", err)
	}

	query := "INSERT INTO game_scores(game_id, player_id, hole_num, score) VALUES "
	query += strings.Join(values, ",")

	if err := db.Exec(query).Error; err != nil {
		log.Printf("SetScoreNew error: %v", err)
	}
}

func DeleteGame(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		log.Printf("DeleteGame error: %v", err)
		return
	}
	printPostForm(r)

	gameID := r.Form.Get("game")

	// Get game from db
	var game Game
	if err := db.Where("id = ?", gameID).Find(&game).Error; err != nil {
		log.Printf("DeleteGame error: %v", err)
	}

	// Make sure game isn't too old
	log.Printf("Time since ending: %f", time.Now().UTC().Sub(game.EndTime).Hours())
	if time.Now().UTC().Sub(game.EndTime).Hours() > 1 {
		log.Print("DeleteGame error: cannot delete game after 1 hours of ending")
		return
	}

	// Delete game
	if err = db.Where("id = ?", gameID).Delete(Game{}).Error; err != nil {
		log.Printf("DeleteGame error: %v", err)
	}

	// Delete all scores attached to game
	if err = db.Where("game_id = ?", gameID).Delete(GameScore{}).Error; err != nil {
		log.Printf("DeleteGame error: %v", err)
	}

	// Delete all players attached to game
	if err = db.Where("game_id = ?", gameID).Delete(GamePlayer{}).Error; err != nil {
		log.Printf("DeleteGame error: %v", err)
	}
}
