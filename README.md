# README

This is supposed to become an API for the MaMpf project.
As of now, only the models and some class methods have been implemented, together with a rake task that imports real world data from csv files. Just play around with it to get a feeling...

* Ruby version: 2.4.0
* Rails Version: 5.1.1

* Database initialization: 
    `rails setup:import_data`
  
  This imports a lot of data from the .csv files in the db/csv folder

* Test suite: rspec
