require 'execute_shell'
require 'sqlite3'
require 'time'
'''
App Name: Mac Battery Life Analyzer
Author: Uzzal Devkota
Database Name: :cycle_count:
Table Name: cycle_count
Table Schema: CREATE TABLE cycle_count(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, date TEXT, count INTEGER);
Pre-Requisites: ruby, rubygems, execute_shell gem, sqlite3 gem
'''
begin
    db = SQLite3::Database.open ":cycle_count:"
    create_table_query = "CREATE TABLE IF NOT EXISTS cycle_count(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, date TEXT, count INTEGER);"
    db.execute create_table_query

    cycle_count_old = 0
    row = db.get_first_row "SELECT * FROM cycle_count ORDER BY id DESC" # cool

    time_old, cycle_count_old = Time.parse(row[1]), row[2].to_i if row # needs parsing becuz date is stored as TEXT

    # Just system_profiler gives detailed report (but all we need here is the System Profiler Power Data Type i.e. SPPowerDataType)
    cycle_count_string = ExecuteShell.run('system_profiler SPPowerDataType | grep Cycle\ Count').to_s

    # extract just the cycle count integer part from the returned string
    cycle_count_new = cycle_count_string.split(" ")[2].to_i

	if cycle_count_new != cycle_count_old
		if cycle_count_old > 0
		    seconds_since_last_cycle_count = Time.now - time_old
			cycle_count_difference = cycle_count_new - cycle_count_old
			# "cycle_count_difference" cycles increased in "seconds_since_last_cycle_count" seconds
			remaining_cycle_count = 1000 - cycle_count_new
			# "remaining_cycle_count" in "(seconds_since_last_cycle_count/cycle_count_difference) * remaining_cycle_count" seconds
			remaining_battery_life_in_seconds = (seconds_since_last_cycle_count/cycle_count_difference) * remaining_cycle_count
			remaining_battery_life_in_years = remaining_battery_life_in_seconds / (3600*24*365)
		end

		db.execute "INSERT INTO cycle_count(date, count) VALUES(?, ?)", Time.now.to_s, cycle_count_new
		rem_life = ""
		File.open('cycle_count.txt', "a") do |f|
			f.puts Time.now
			f.puts "Cycle Count: " + cycle_count_new.to_s
			rem_life = "Remaining Battery Life: " + remaining_battery_life_in_years.round(2).to_s + " years" if remaining_battery_life_in_years
			f.puts rem_life
			f.puts "\n"
		end
		puts rem_life
	end
rescue SQLite3::Exception => e 
    puts "Exception occured"
    puts e
ensure
    db.close if db
end