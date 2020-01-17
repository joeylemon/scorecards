package main

import (
	"log"
	"math"
)

func degrees2radians(degrees float64) float64 {
	return degrees * math.Pi / 180
}

func distance(lat1 float64, lon1 float64, lat2 float64, lon2 float64) float64 {
	degreesLat := degrees2radians(lat2 - lat1)
	degreesLong := degrees2radians(lon2 - lon1)
	a := (math.Sin(degreesLat/2)*math.Sin(degreesLat/2) +
		math.Cos(degrees2radians(lat1))*
			math.Cos(degrees2radians(lat2))*math.Sin(degreesLong/2)*
			math.Sin(degreesLong/2))
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	d := 6371 * c

	return d
}

func getClosestCourse(lat float64, lon float64) Course {
	if lat == 0.0 && lon == 0.0 {
		return Course{ID: 1}
	}

	var courses []Course
	if err := db.Find(&courses).Error; err != nil {
		log.Printf("getClosestCourse error: %v", err)
		return Course{ID: 1}
	}

	closest := courses[0]
	shortestDist := distance(lat, lon, closest.Latitude, closest.Longitude)
	for i, course := range courses {
		if i == 0 {
			continue
		}

		dist := distance(lat, lon, course.Latitude, course.Longitude)
		if dist < shortestDist {
			closest = course
			shortestDist = dist
		}
	}

	return closest
}
