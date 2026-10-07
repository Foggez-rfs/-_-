package geo

import "math"

const earthRadiusM = 6371000

func Haversine(lat1, lon1, lat2, lon2 float64) float64 {
dLat := (lat2 - lat1) * math.Pi / 180
dLon := (lon2 - lon1) * math.Pi / 180
lat1R := lat1 * math.Pi / 180
lat2R := lat2 * math.Pi / 180
a := math.Sin(dLat/2)*math.Sin(dLat/2) +
math.Cos(lat1R)*math.Cos(lat2R)*math.Sin(dLon/2)*math.Sin(dLon/2)
c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
return earthRadiusM * c
}
