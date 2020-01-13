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

    var currentTrendIndex = 0
    var currentObject: ObjectResponse?
    
    let trendingURL = URL(string: "https://demo0040494.mockable.io/api/v1/trending")!
    let objectURL = URL(string: "https://demo0040494.mockable.io/api/v1/object/")!
    
    lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(frame: view.bounds)
        spinner.backgroundColor = UIColor.gray
        spinner.color = UIColor.white
        view.addSubview(spinner)
        return spinner
    }()
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        webView.isHidden = true
        nextButton.isEnabled = false
        showNextTrend { [unowned self]  in
            self.nextButton.isEnabled = true
            if self.objects[self.currentTrendIndex].type == "text" {
                self.textView.isHidden = false
                self.textView.text = self.objects[self.currentTrendIndex].contents
            } else {
                let url = URL(string: self.objects[self.currentTrendIndex].url!)!
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
    
    private func downloadObjectFrom(_ url: URL, with id: Int, complitionHandler: @escaping (ObjectResponse?, URLResponse?, Error?) -> Void) {
        var object: ObjectResponse?
        let url = url.appendingPathComponent(String(id))
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                complitionHandler(object, response, error)
                return
            }
            do {
                object = try JSONDecoder().decode(ObjectResponse.self, from: data)
            } catch {
                complitionHandler(object, response, error)
            }
            complitionHandler(object, response, error)
        }.resume()
    }
    
    private func showNextTrend(complitionHandler: @escaping () -> Void) {
        var nextTrendIndex = currentTrendIndex
        
        if trendings.count == 0 {
            nextTrendIndex = currentTrendIndex + 1
            downloadFirstObject { (object, response, error) in
                DispatchQueue.main.async {
                    self.errorHandler(object, with: response, with: error)
                }
            }
        } else {
            nextTrendIndex = currentTrendIndex + 1
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
    
    private func downloadFirstObject(complitionHandler: @escaping(ObjectResponse?, URLResponse?, Error?) -> Void) {
        var aT = [TrendingResponse]()
        var object: ObjectResponse?
        var tmpresponse: URLResponse?
        var tmperror: Error?
        URLSession.shared.dataTask(with: trendingURL) { [unowned self] (data, response, error) in
            tmpresponse = response
            tmperror = error
            
            guard let data = data else {
                complitionHandler(object, tmpresponse, tmperror)
                return
            }
            do {
                aT = try JSONDecoder().decode([TrendingResponse].self, from: data)
                self.trendings = aT
            } catch {
                tmperror = error
                complitionHandler(object, tmpresponse, tmperror)
            }
            
            let aUrl = self.objectURL.appendingPathComponent(String(aT[0].id))
            URLSession.shared.dataTask(with: aUrl) { (data, response, error) in
                tmpresponse = response
                tmperror = error
                guard let data = data else {
                    complitionHandler(object, tmpresponse, tmperror)
                    return
                }
                do {
                    object = try JSONDecoder().decode(ObjectResponse.self, from: data)
                } catch {
                    tmperror = error
                    complitionHandler(object, tmpresponse, tmperror)
                }
                complitionHandler(object, tmpresponse, tmperror)
            }.resume()
        }.resume()
    }
    
    private func errorHandler(_ object: ObjectResponse?, with response: URLResponse?, with error: Error?) {
        
        if error != nil || object == nil {
            self.textView.text = "Client error!"
            self.nextButton.isEnabled = true
            return
        }
        
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            self.textView.text = "Server error!"
            self.nextButton.isEnabled = true
            return
        }
        
        if object == nil {
            self.nextButton.isEnabled = true
            self.textView.text = "Corrupted response"
            return
        } else {
            self.objects.append(object!)
            self.textView.text = self.objects[0].contents
            self.nextButton.isEnabled = true
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

