//
//  ViewController.swift
//  Test Task @ iOS Developer | Offerwall
//
//  Created by Stas Shetko on 2/01/20.
//  Copyright © 2020 Stas Shetko. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    var trendings = [TrendingResponse]()
    var objects = [ObjectResponse]()
    
    lazy var spinner: UIActivityIndicatorView = {
              let spinner = UIActivityIndicatorView(frame: view.bounds)
          spinner.backgroundColor = UIColor.gray
        spinner.color = UIColor.white
          view.addSubview(spinner)
        return spinner
    }()
    
    var currentTrendIndex = 0
    var currentObject: ObjectResponse?
    
    let trendingURL = URL(string: "https://demo0040494.mockable.io/api/v1/trending")!
    let objectURL = URL(string: "https://demo0040494.mockable.io/api/v1/object/")!
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        webView.isHidden = true
        showNextTrend { [unowned self]  in
            if self.objects[self.currentTrendIndex].type == "text" {
                self.textView.isHidden = false
                self.textView.text = self.objects[self.currentTrendIndex].contents
            } else {
                let url = URL(string: self.objects[self.currentTrendIndex].url!)!
//                let url = URL(string: "https://www.google.com/doodles/")!
                print(url)
                self.showWebView(url)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.layer.cornerRadius = 8
        webView.isHidden = true
        webView.navigationDelegate = self

        spinner.startAnimating()
        downloadFirstObject { (object, response, error) in
            DispatchQueue.main.async {
                self.errorHandler(object, with: response, with: error)
                self.spinner.stopAnimating()
            }
        }
    }
    
    func query(complitionHandler: @escaping() -> Void) {
        var aT = [TrendingResponse]()
        URLSession.shared.dataTask(with: trendingURL) { [unowned self] (data, response, error) in
            if error != nil || data == nil {
                print("Client error!")
                return
            }
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Server error!")
                return
            }
            guard let data = data else {
                print("Corrupted response")
                return
            }
            do {
                aT = try JSONDecoder().decode([TrendingResponse].self, from: data)
                self.trendings = aT
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
            
            let aUrl = self.objectURL.appendingPathComponent(String(aT[0].id))
            URLSession.shared.dataTask(with: aUrl) { (data, response, error) in
                if error != nil || data == nil {
                    print("Client error!")
                    return
                }
                guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    print("Server error!")
                    return
                }
                guard let data = data else {
                    print("Corrupted response")
                    return
                }
                do {
                    let object = try JSONDecoder().decode(ObjectResponse.self, from: data)
                    self.objects.append(object)
                } catch {
                    print("JSON error: \(error.localizedDescription)")
                }
                complitionHandler()
            }.resume()
        }.resume()
    }
    
    private func downloadObjectFrom(_ url: URL, with id: Int, complitionHandler: @escaping (ObjectResponse?, URLResponse?, Error?) -> Void) {
        print(#function)
        var object: ObjectResponse?
        let url = url.appendingPathComponent(String(id))
        URLSession.shared.dataTask(with: url) {  (data, response, error) in
            guard let data = data else {
                print("Corrupted response")
                complitionHandler(object, response, error)
                return
            }
            do {
                object = try JSONDecoder().decode(ObjectResponse.self, from: data)
            } catch {
                print("JSON error: \(error.localizedDescription)")
                complitionHandler(object, response, error)
            }
            complitionHandler(object, response, error)
        }.resume()
    }
    
    private func showNextTrend(complitionHandler: @escaping () -> Void) {
        let nextTrendIndex = currentTrendIndex + 1

        if trendings.count == 0 {
            downloadFirstObject { (object, response, error) in
                DispatchQueue.main.async {
                    self.errorHandler(object, with: response, with: error)
                }
            }
        } else {
            if nextTrendIndex == trendings.count || objects.count == trendings.count {
                currentTrendIndex = nextTrendIndex % trendings.count
                currentObject = objects[currentTrendIndex]
                complitionHandler()
            } else {
                currentTrendIndex = nextTrendIndex
                downloadObjectFrom(objectURL, with: trendings[currentTrendIndex].id) { [unowned self] (object, response, error) in
                    DispatchQueue.main.async {
                        self.errorHandler(object, with: response, with: error)
                        complitionHandler()
                    }
                }
            }
        }
    }
    
    private func showWebView(_ url: URL) {
        webView.isHidden = false
        textView.isHidden = true
        let request = URLRequest(url: url)
        webView.load(request)
        self.view.bringSubviewToFront(self.nextButton)
    }
    
    func downloadFirstObject(complitionHandler: @escaping(ObjectResponse?, URLResponse?, Error?) -> Void) {
        var aT = [TrendingResponse]()
        var object: ObjectResponse?
        var tmpresponse: URLResponse?
        var tmperror: Error?
        URLSession.shared.dataTask(with: trendingURL) { [unowned self] (data, response, error) in
            tmpresponse = response
            tmperror = error
            
            guard let data = data else {
                print("Corrupted response")
                complitionHandler(object, tmpresponse, tmperror)
                return
            }
            do {
                aT = try JSONDecoder().decode([TrendingResponse].self, from: data)
                self.trendings = aT
            } catch {
                tmperror = error
                print("JSON error: \(error.localizedDescription)")
                complitionHandler(object, tmpresponse, tmperror)
            }
            
            let aUrl = self.objectURL.appendingPathComponent(String(aT[0].id))
            URLSession.shared.dataTask(with: aUrl) { (data, response, error) in
                tmpresponse = response
                tmperror = error
                guard let data = data else {
                    print("Corrupted response")
                    complitionHandler(object, tmpresponse, tmperror)
                    return
                }
                do {
                    object = try JSONDecoder().decode(ObjectResponse.self, from: data)
                } catch {
                    tmperror = error
                    print("JSON error: \(error.localizedDescription)")
                    complitionHandler(object, tmpresponse, tmperror)
                }
                complitionHandler(object, tmpresponse, tmperror)
            }.resume()
        }.resume()
    }
    
    private func errorHandler(_ object: ObjectResponse?, with response: URLResponse?, with error: Error?) {
        
        if error != nil || object == nil {
            print("Client error!")
            self.textView.text = "Client error!"
            return
        }
        
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            self.textView.text = "Server error!"
            print("Server error!")
            return
        }
        
        if object == nil {
            print("Corrupted response")
            self.textView.text = "Corrupted response"
            return
        } else {
            self.objects.append(object!)
            self.textView.text = self.objects[0].contents
        }
        
    }
}
//MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if trendings.count != objects.count {
            spinner.startAnimating()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()

    }

}

