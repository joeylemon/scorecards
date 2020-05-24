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

// ListEntries lists all games and their information
func ListEntries(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	var games []GameListing
	if err := db.Preload("Course").Raw(`
		select g.id, g.hole_count, g.front, g.date, g.end_time, 
		c.id as course_id,
		group_concat(p.name separator ', ') as people,
		w.winners
		from games g

		left join 
		(select s2.game_id, group_concat(p2.name separator ', ') as winners
		from total_scores s1
		join (
			select game_id, min(total_score) as winner_score from total_scores
			group by game_id
		) s2
		on s1.total_score=s2.winner_score and s1.game_id=s2.game_id
		left join players p2 on p2.id=s1.player_id
		left join games g2 on g2.id=s1.game_id
		where TIMESTAMPDIFF(HOUR, g2.date, g2.end_time) != 8
		group by s1.game_id) w on w.game_id=g.id

		left join courses c on c.id=g.course_id
		left join game_players gp on gp.game_id=g.id
		left join players p on gp.player_id=p.id
		group by g.id
		order by g.date desc
	`).Find(&games).Error; err != nil {
		handleError(err)
		return
	}

	for i, game := range games {
		// Format date into string
		games[i].DateString = game.Date.Format("Jan 2 2006")

		// Create string array of player names
		games[i].Players = strings.Split(game.People, ", ")

		if len(game.Winners) > 0 {
			// Determine duration of the game
			durationTime := time.Time{}.Add(game.EndTime.Sub(game.Date))
			games[i].DurationString = fmt.Sprintf("%dh %dm", durationTime.Hour(), durationTime.Minute())

			// Set winner to either tie or the winner's name
			winners := strings.Split(game.Winners, ", ")
			if len(winners) >= 2 {
				games[i].Winner = "Tie"
			} else {
				games[i].Winner = game.Winners
			}
		} else {
			// If there are no winners, the game is still occurring
			games[i].DurationString = "In progress"
			games[i].Winner = "Incomplete"
		}
	}

	writeJSON(w, games)
}

// CreateGame creates a new game with the given players
func CreateGame(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		handleError(err)
		return
	}
	printPostForm(r)

	// Application will send request regardless of if no players were selected
	// Prevent creation of empty game
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

	players := strings.Split(r.Form.Get("players"), ",") // String-separated list of names
	holes, _ := strconv.Atoi(r.Form.Get("holes"))        // 9 or 18
	front := r.Form.Get("front") == "true"               // Front or back

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
		handleError(err)
	}

	// Associate players with the game
	for _, playerID := range players {
		var gamePlayer GamePlayer
		gamePlayer.GameID = game.ID
		gamePlayer.PlayerID, _ = strconv.Atoi(playerID)
		if err = db.Create(&gamePlayer).Error; err != nil {
			handleError(err)
		}

		// Create empty scores
		for i := 1; i <= holes; i++ {
			var gameScore GameScore
			gameScore.GameID = game.ID
			gameScore.PlayerID, _ = strconv.Atoi(playerID)
			gameScore.HoleNum = i
			gameScore.Score = 0
			if err = db.Create(&gameScore).Error; err != nil {
				handleError(err)
			}
		}
	}
}

// GetGame returns the scorecard for a given game
func GetGame(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		handleError(err)
		return
	}
	printPostForm(r)

	id := r.Form.Get("id")

	var game Game
	if err := db.Where("id = ?", id).Find(&game).Error; err != nil {
		handleError(err)
	}

	// Get a list of hole pars
	var pars []int
	var coursePars []CoursePar
	if err := db.Where("course_id = ?", game.CourseID).Order("hole_num asc").Find(&coursePars).Error; err != nil {
		handleError(err)
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
		handleError(err)
	}

	var people []string
	for _, player := range players {
		people = append(people, player.Name)
	}
	peopleString := strings.Join(people, ", ")

	scoreSums := make(map[int]int)
	var scores []GameScore
	if err = db.Where("game_id = ?", id).Find(&scores).Error; err != nil {
		handleError(err)
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

// SetScore sets the scorecard for a given game
func SetScore(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		handleError(err)
		return
	}
	printPostForm(r)

	gameID := r.Form.Get("gameID")

	// Get game from db
	var game Game
	if err := db.Where("id = ?", gameID).Find(&game).Error; err != nil {
		handleError(err)
	}

	// Make sure game isn't over a day old
	if time.Now().UTC().Sub(game.EndTime).Hours() > 1 {
		handleError(fmt.Errorf("cannot change game score after 1 hour of ending"))
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
			handleError(err)
		}
	}

	if err := db.Delete(GameScore{}, "game_id = ?", gameID).Error; err != nil {
		handleError(err)
	}

	query := "INSERT INTO game_scores(game_id, player_id, hole_num, score) VALUES "
	query += strings.Join(values, ",")

	if err := db.Exec(query).Error; err != nil {
		handleError(err)
	}
}

// DeleteGame deletes a given game
func DeleteGame(w http.ResponseWriter, r *http.Request) {
	enableCors(&w)

	err := r.ParseForm()
	if err != nil {
		handleError(err)
		return
	}
	printPostForm(r)

	gameID := r.Form.Get("game")

	// Get game from db
	var game Game
	if err := db.Where("id = ?", gameID).Find(&game).Error; err != nil {
		handleError(err)
	}

	// Make sure game isn't too old
	log.Printf("Time since ending: %f", time.Now().UTC().Sub(game.EndTime).Hours())
	if time.Now().UTC().Sub(game.EndTime).Hours() > 24 {
		handleError(fmt.Errorf("cannot delete game after 24 hours of ending"))
		return
	}

	// Delete game
	if err = db.Where("id = ?", gameID).Delete(Game{}).Error; err != nil {
		handleError(err)
	}
}
