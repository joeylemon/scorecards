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

func (g Game) isExpired() bool {
	return time.Now().UTC().Sub(g.EndTime).Hours() > 24
}

type GameListing struct {
	ID             int `gorm:"unique;not null;primary_key"`
	HoleCount      int
	Front          bool
	Date           time.Time `json:"-"`
	EndTime        time.Time `json:"-"`
	DateString     string    `gorm:"-"`
	DurationString string    `gorm:"-"`
	CourseID       int
	Course         Course
	People         string
	Players        []string `gorm:"-"`
	Winners        string   `json:"-"`
	Winner         string
}

func (GameListing) TableName() string {
	return "games"
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

type Handicap struct {
	GameID     int
	PlayerID   int
	TotalScore int
	Rating     float64
	Slope      float64
}

func (Handicap) TableName() string {
	return "total_scores"
}

type HandicapPlayer struct {
	ID            int `gorm:"unique;not null;primary_key"`
	Name          string
	LatestScores  []Handicap     `gorm:"-"`
	Differentials []HandicapGame `gorm:"-"`
	Index         float64        `gorm:"-"`
}

func (HandicapPlayer) TableName() string {
	return "players"
}

type HandicapGame struct {
	GameID       int
	Differential float64
}

type LeaderboardQuery struct {
	Title   string
	Query   string `json:"-"`
	Entries []LeaderboardEntry
}

type LeaderboardEntry struct {
	Name     string
	Value    string
	Games    string `json:"-"`
	GameList []int  `gorm:"-"`
}
