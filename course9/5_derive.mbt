///|
enum Weekday {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
} derive(Eq, Compare)

///|
test {
  inspect(Monday < Tuesday, content="true")
  inspect(Sunday < Monday, content="false")
}
