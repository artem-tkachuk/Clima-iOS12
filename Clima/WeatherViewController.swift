//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Edited by Artem Tkachuk on 10.09.2019
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON


class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "d83fa7e532f123de191764c7c185a6a6"
    /***Get your own App ID at https://openweathermap.org/appid ****/
    

    //TODO: Declare instance variables here
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var scale: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set scale to Celsius by default
        scale.setOn(false, animated: false)
        
        //TODO:Set up the location manager here.
        locationManager.delegate = self
        
        //get location data best for the job, meaning we want less battery use and quick result
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        //get permission from the user to get location data when the app is in use
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    
    //MARK: - Changing the scale
    /***************************************************************/
    
    @IBAction func userChangedScale(_ sender: Any) {
        scale.setOn(scale.isOn, animated: true)   //update the toggle. isOn has updated value!
        
        let currentTemp = weatherDataModel.temperature
        
        weatherDataModel.temperature = updateTemperature(scale: scale, temp: currentTemp)
        
        updateUIWithWeatherData()       //apply changes
    }
    
    
    func updateTemperature(scale: UISwitch, temp: Double) -> (Double) {
        if scale.isOn {
            return 1.8 * Double(temp) + Double(32)    //if Fahrenheit is wanted
        }
        return Double(temp  - 32) / 1.8        //to Celsius
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    //Write the getWeatherData method here:
    
    func getWeatherData(url : String, parameters : [String: String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Success! Got the weather data!")
                
                let weatherJSON : JSON = JSON(response.result.value!) //force unwrapping
                self.updateWeatherData(json: weatherJSON)             //look for this method inside the current class
                
            } else {
                print("Error \(String(describing: response.result.error))")
                self.cityLabel.text = "Connection issues"
            }
        }
    }

    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    
    //Write the updateWeatherData method here:
    func updateWeatherData(json: JSON) {
        //NOT force unwrapping, but optional binding instead
        if let temp = json["main"]["temp"].double {
            
            // converting to Celcius or 
            var temperature = temp - 273.15
            
            if scale.isOn { //if the city was changed while Fahrenheit was on
                temperature = 1.8 * temperature + 32
            }
            
            weatherDataModel.temperature = temperature
            
            weatherDataModel.city = json["name"].stringValue
            
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithWeatherData()
            
        } else {
            cityLabel.text = "Weather Unavailable"
        }
    }

    
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    
    //Write the updateUIWithWeatherData method here:
    
    func updateUIWithWeatherData() {
        cityLabel.text = String(weatherDataModel.city)
        temperatureLabel.text = "\(Int(weatherDataModel.temperature))°"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]   //get last location received, the most accurate
        if location.horizontalAccuracy > 0 {            //check whether the location is valid
            locationManager.stopUpdatingLocation()      //stop updating the location to save user's battery!
            locationManager.delegate = nil
            
            print("longitude = \(location.coordinate.longitude), latitude = \(location.coordinate.latitude)")
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            let params: [String: String] = ["lat": latitude, "lon": longitude, "appid": APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Loc. unavailable"
    }
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    
    //Write the userEnteredANewCityName Delegate method here:
    func userEnteredANewCityName(city: String) {
        let params : [String : String] = ["q": city, "appid": APP_ID]
        
        getWeatherData(url: WEATHER_URL, parameters: params)
        
    }

    
    //Write the PrepareForSegue Method here
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            
            destinationVC.delegate = self
        }
    }
    
    
    
}


