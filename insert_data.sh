#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Clear existing data
$PSQL "TRUNCATE games, teams RESTART IDENTITY CASCADE"

# Declare an associative array to store unique team names
declare -A teams

# Read the CSV file and populate the array with unique team names
while IFS=',' read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS; do
  if [[ $YEAR != "year" ]]; then
    teams["$WINNER"]=1
    teams["$OPPONENT"]=1
  fi
done < games.csv

# Insert unique teams into the teams table
for TEAM in "${!teams[@]}"; do
  echo "Inserting team: $TEAM"  # Debugging output
  INSERT_TEAM_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$TEAM')")
  if [[ $INSERT_TEAM_RESULT == "INSERT 0 1" ]]; then
    echo "Successfully inserted team: $TEAM"
  else
    echo "Failed to insert team: $TEAM"
  fi
done

# Read the CSV file and insert game data into the games table
while IFS=',' read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS; do
  if [[ $YEAR != "year" ]]; then
    # Get the team IDs for winner and opponent
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    
    # Debugging output for team IDs
    echo "Winner: $WINNER, ID: $WINNER_ID"
    echo "Opponent: $OPPONENT, ID: $OPPONENT_ID"
    
    # Insert game data into the games table
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)")
    if [[ $INSERT_GAME_RESULT == "INSERT 0 1" ]]; then
      echo "Successfully inserted game: $YEAR, $ROUND, $WINNER vs $OPPONENT"
    else
      echo "Failed to insert game: $YEAR, $ROUND, $WINNER vs $OPPONENT"
    fi
  fi
done < games.csv
