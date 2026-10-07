#! /bin/bash

set -e

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet --set=ON_ERROR_STOP=1"

run_query() {
  local query="$1"
  shift
  printf '%s\n' "$query" | $PSQL "$@"
}

echo
echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo

print_services() {
  run_query "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

print_services
read SERVICE_ID_SELECTED

while [[ "$(run_query "SELECT EXISTS (SELECT 1 FROM services WHERE service_id::text = :'service_id');" --set="service_id=$SERVICE_ID_SELECTED")" != "t" ]]; do
  echo
  echo "I could not find that service. What would you like today?"
  print_services
  read SERVICE_ID_SELECTED
done

SERVICE_NAME=$(run_query "SELECT name FROM services WHERE service_id::text = :'service_id';" --set="service_id=$SERVICE_ID_SELECTED")

echo
echo "What's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_ID=$(run_query "SELECT customer_id FROM customers WHERE phone = :'customer_phone';" --set="customer_phone=$CUSTOMER_PHONE")

if [[ -z "$CUSTOMER_ID" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_ID=$(run_query "INSERT INTO customers (name, phone) VALUES (:'customer_name', :'customer_phone') RETURNING customer_id;" --set="customer_name=$CUSTOMER_NAME" --set="customer_phone=$CUSTOMER_PHONE")
else
  CUSTOMER_NAME=$(run_query "SELECT name FROM customers WHERE customer_id = :'customer_id';" --set="customer_id=$CUSTOMER_ID")
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

run_query "INSERT INTO appointments (customer_id, service_id, time) VALUES (:'customer_id', :'service_id', :'service_time');" --set="customer_id=$CUSTOMER_ID" --set="service_id=$SERVICE_ID_SELECTED" --set="service_time=$SERVICE_TIME" > /dev/null

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
