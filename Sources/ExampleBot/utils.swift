// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import Dispatch
import Foundation
import SwiftDiscord

func createFormatMessage(withStats stats: [String: Any]) -> DiscordEmbed {
    func uptimeString(fromSeconds seconds: Double) -> String {
        var timeString = ""
        var time = Int(seconds)

        if time >= 3600 {
            timeString += "Hours: \(time / 3600) "
            time %= 3600
        }

        timeString += "Minutes: \(time / 60) "
        timeString += "Seconds: \(time % 60)"

        return timeString
    }

    let guilds = stats["numberOfGuilds"] as! Int
    let textChannels = stats["numberOfTextChannels"] as! Int
    let voiceChannels = stats["numberOfVoiceChannels"] as! Int
    let numberOfLoadedUsers = stats["numberOfLoadedUsers"] as! Int
    let totalNumberOfUsers = stats["totalNumberOfUsers"] as! Int
    let shards = stats["shards"] as! Int
    let fieldMaker = DiscordEmbed.Field.init(name:value:inline:)
    let uptime = stats["uptime"] as! Double

    var embed = DiscordEmbed(title: "\(stats["name"] as! String)'s stats",
                             description: "[Source](\(sourceUrl.absoluteString))",
                             author: DiscordEmbed.Author(name: "nuclearace",
                                                         iconUrl: authorImage,
                                                         url: authorUrl),
                             color: 0xF07F07)

    embed.fields.append(fieldMaker("Guilds", String(guilds), false))
    embed.fields.append(fieldMaker("Text Channels", String(textChannels), true))
    embed.fields.append(fieldMaker("Voice Channels", String(voiceChannels), true))
    embed.fields.append(fieldMaker("Total Channels", String(voiceChannels + textChannels), true))
    embed.fields.append(fieldMaker("Loaded Users", String(numberOfLoadedUsers), true))
    embed.fields.append(fieldMaker("Total Users", String(totalNumberOfUsers), true))
    embed.fields.append(fieldMaker("Shards", String(shards), true))

    if let memory = stats["memory"] as? Double {
        embed.fields.append(fieldMaker("Memory", "\(memory) MB", true))
    }

    embed.fields.append(fieldMaker("Uptime", "\(uptimeString(fromSeconds: uptime))", true))

    return embed
}

func createForecastEmbed(withForecastData data: [String: Any], tomorrow: Bool) -> DiscordEmbed? {
    guard let forecastData = data["forecast"] as? [String: Any] else { return nil }
    guard let current = data["current_observation"] as? [String: Any],
          let displayLocation = current["display_location"] as? [String: Any],
          let full = displayLocation["full"] as? String else {
        return nil
    }
    guard let textForecasts = forecastData["txt_forecast"] as? [String: Any] else { return nil }
    guard let forecasts = textForecasts["forecastday"] as? [[String: Any]] else { return nil }

    let days = Array(forecasts[tomorrow ? 2...3 : 0...1])
    let day = days[0]
    let night = days[1]

    var embed = DiscordEmbed(title: "Forecast for \(full)",
                             description: "",
                             color: 0xF07F07)

    let fieldMaker = DiscordEmbed.Field.init(name:value:inline:)

    embed.fields.append(fieldMaker(day["title"] as! String + " Fahrenheit masterrace",
        day["fcttext"] as! String, false))
    embed.fields.append(fieldMaker(night["title"] as! String + " Fahrenheit masterrace",
        night["fcttext"] as! String, false))
    embed.fields.append(fieldMaker(day["title"] as! String + " Metric plebrace",
        day["fcttext_metric"] as! String, false))
    embed.fields.append(fieldMaker(night["title"] as! String + " Metric plebrace",
        night["fcttext_metric"] as! String, false))

    return embed
}

func createWeatherEmbed(withWeatherData data: [String: Any]) -> DiscordEmbed? {
    guard let displayLocation = data["display_location"] as? [String: Any],
          let fullName = displayLocation["full"] as? String, let observationTime = data["observation_time"] as? String
          else {
        return nil
    }

    var embed = DiscordEmbed(title: "Current Conditions for \(fullName)",
                             description: observationTime,
                             color: 0xF07F07)

    let fieldMaker = DiscordEmbed.Field.init(name:value:inline:)

    if let weather = data["weather"] as? String {
        embed.fields.append(fieldMaker("Weather", weather, false))
    }

    if let feelsLike = data["feelslike_string"] as? String {
        embed.fields.append(fieldMaker("Feels like", feelsLike, true))
    }

    if let temp = data["temperature_string"] as? String {
        embed.fields.append(fieldMaker("Temperature", temp, true))
    }

    if let dewPoint = data["dewpoint_string"] as? String {
        embed.fields.append(fieldMaker("Dew point", dewPoint, true))
    }

    if let precipToday = data["precip_today_string"] as? String {
        embed.fields.append(fieldMaker("Precipitation today", precipToday, true))
    }

    if let winds = data["wind_string"] as? String {
        embed.fields.append(fieldMaker("Wind", winds, true))
    }

    if let visibilityMi = data["visibility_mi"] as? String, let visibilityKh = data["visibility_km"] as? String {
        embed.fields.append(fieldMaker("Visibility", "\(visibilityMi) MI (\(visibilityKh) KM)", true))
    }

    return embed
}

func createGetRequest(for string: String) -> URLRequest? {
    guard let url = URL(string: string) else { return nil }

    var request = URLRequest(url: url)

    request.httpMethod = "GET"

    return request
}

func getRequestData(for request: URLRequest, callback: @escaping (Data?) -> Void) {
    URLSession.shared.dataTask(with: request) {data, response, error in
        guard data != nil, error == nil, let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
            callback(nil)

            return
        }

        callback(data!)
    }.resume()
}

func getForecastData(forLocation location: String, withApiKey apiKey: String) -> [String: Any]? {
    let escapedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let stringUrl = "https://api.wunderground.com/api/\(apiKey)/conditions/forecast/q/\(escapedLocation).json"
    let weatherUndergroundData = getWeatherUndergroundData(withURL: stringUrl) as? [String: Any]

    return weatherUndergroundData
}

func getWeatherData(forLocation location: String, withApiKey apiKey: String) -> [String: Any]? {
    let escapedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    let stringUrl = "https://api.wunderground.com/api/\(apiKey)/conditions/q/\(escapedLocation).json"
    let weatherUndergroundData = getWeatherUndergroundData(withURL: stringUrl) as? [String: Any]

    return weatherUndergroundData?["current_observation"] as? [String: Any]
}

func getWeatherUndergroundData(withURL url: String) -> Any? {
    guard let request = createGetRequest(for: url) else {
        return nil
    }

    let lock = DispatchSemaphore(value: 0)
    var weatherData: Any?

    getRequestData(for: request) {data in
        guard let data = data else {
            lock.signal()

            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else {
            lock.signal()

            return
        }

        weatherData = json

        lock.signal()
    }

    lock.wait()

    return weatherData
}
