#!/bin/bash

# Start FlareSolverr in the background
echo "Starting FlareSolverr..."
/app/FlareSolverr/flaresolverr --port=$FLARESOLVERR_PORT &

# Start Jackett
echo "Starting Jackett..."
exec /app/Jackett/jackett --NoRestart --NoUpdates -p $PORT
