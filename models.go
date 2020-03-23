package main

import "time"

// Game describes a game
type Game struct {
	ID             int `gorm:"unique;not null;primary_key"`
	HoleCount      int
	CourseID       int
	Front          bool
	Course         Course
	Date           time.Time `json:"-"`
	EndTime        time.Time `json:"-"`
	DateString     string    `gorm:"-"`
	DurationString string    `gorm:"-"`
	Players        []string  `gorm:"-"`
	People         string    `gorm:"-"`
	Winner         string    `gorm:"-"`
}

func (Game) TableName() string {
	return "games"
}

func (g Game) isLastHole(hole int) bool {
	return hole == g.HoleCount
}

// Course describes a golf course
type Course struct {
	ID        int `gorm:"unique;not null;primary_key"`
	Name      string
	Latitude  float64
	Longitude float64
}

func (Course) TableName() string {
	return "courses"
}

// CoursePar describes the par score for a hole on a given course
type CoursePar struct {
	CourseID int
	HoleNum  int
	Par      int
}

func (CoursePar) TableName() string {
	return "course_pars"
}

// Player describes a player
type Player struct {
	ID    int `gorm:"unique;not null;primary_key"`
	Name  string
	Color string
}

func (Player) TableName() string {
	return "players"
}

// GamePlayer associates a player to a game
type GamePlayer struct {
	GameID   int
	PlayerID int
	Player   Player
}

func (GamePlayer) TableName() string {
	return "game_players"
}

// GameScore associates a score to a game and a hole
type GameScore struct {
	GameID   int `json:"-"`
	PlayerID int
	HoleNum  int `json:"-"`
	Score    int
}

func (GameScore) TableName() string {
	return "game_scores"
}

type LeaderboardQuery struct {
	Title    string
	Query    string
}

type LeaderboardEntry struct {
	Name  string
	Value string
}
