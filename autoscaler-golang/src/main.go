package main

// TODO: implement the autoscaler here

// Returns a date time string for a using in a REST API call to Camunda Engine
// + is NOT URL-escaped
//
//  Args:
//    dateTime: time.Time object to convert
//
//  Returns:
//    string: String in the yyyy-MM-ddTHH:mm:ss.SSSZ format
//
//  Example: 2021-01-31T12:34:56.789+0100
func formatDateCamunda(dateTime time.Time) string {
	return dateTime.Format("2006-01-02T15:04:05.000+0000")
}
