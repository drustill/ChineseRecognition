//
//  WKWebView.swift
//  china
//
//  Created by Dru Still on 4/15/23.
//
import WebKit
import JavaScriptCore

class JSViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    var jsContext: JSContext = JSContext()

    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = Bundle.main.url(forResource: "hanzi", withExtension: "js", subdirectory: "hanzi-tools-combine")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    func javascriptShit(input: String, completion: @escaping ([String]) -> Void) {
        let urlString = "http://localhost:3000/api/pinyin/\(input)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url = URL(string: urlString ?? "") {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Pinyin: \(responseString)")
                    completion([responseString])
                } else {
                    print("Could not parse response as string")
                }
                
            }.resume()
        } else {
            print("Invalid URL")
        }
    }

}
