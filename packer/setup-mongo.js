use go-mongodb
db.createUser(
   {
      user: "tasky-user",
      pwd: "superAwesomePassword",
      roles: [
         { role: "readWrite", db: "go-mongodb" },
         { role: "read", db: "reporting" }]
   }
)
