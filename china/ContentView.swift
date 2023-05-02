//
//  ContentView.swift
//  china
//
//  Created by Dru Still on 4/10/23.
//

/*
 Writing plans for the app here because the ep formal is soon and i dont have time to do this shit rn and i dont wanna forget it:
 i wish i could write a book
 
 - fix the error that happens when u click clear and then try and draw (it auto clears - prob smething small gonna be annoying asf to find)
 - make the code more organized this shit is getting ugly it should not be in one file
 - learn how to play with swiftUI - want to change the layout of the app - i kinda like how it is though -;
    + BIG FEATURE: TRANSLATE TO PINYINNN 
    + Take the write here shit away and just make the box obviously a writable area
    + Make the box that displays the characters scrollable (or just fuckin display less the model is not that good)
    + try to improve the recognition
    + BIG FEATURE: Implement a swipe to a new page, and on the second page list the characters that have been written the most + how many times they've been written
 
 Good shit you did it all - 4/27/23
 - new plans: make the code prettier
              make the app prettier (i want it PINK!!!!:333333333333333)
 */

import SwiftUI
import MLKitDigitalInkRecognition
import MLKitVision
import MLKitTranslate


protocol DrawingViewDelegate: AnyObject {
    func didRecognizeCharacters(_ characters: [String])
}

class DrawingViewDelegateWrapper: DrawingViewDelegate {
    var contentView: ContentView?
    
    init(contentView: ContentView) {
        self.contentView = contentView
    }
    
    func didRecognizeCharacters(_ characters: [String]) {
        contentView?.didRecognizeCharacters(characters)
    }
}

struct ContentView: View {
    
    @State private var clearDrawing = false
    @State var recognizedCharacters: [String] = []
    @State var charCounts: [String : (String, Int)] = [String : (String, Int)]()
    @State var selectedCharacter: String?
    
    func didRecognizeCharacters(_ characters: [String]) {
        self.recognizedCharacters = characters
    }
    
    var body: some View {
        TabView {
            VStack(spacing: 16) {
                Color.black.opacity(0.05).ignoresSafeArea()
                    .edgesIgnoringSafeArea(.all)
                DrawingView(clearDrawing: $clearDrawing, selectedCharacter: $selectedCharacter, delegate: DrawingViewDelegateWrapper(contentView: self))
                    .frame(width: UIScreen.main.bounds.width - 32, height: 500)
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                
                Button(action: {
                    self.clearDrawing.toggle()
                }) {
                    Text("Clear")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 5)
                }
                RecognizedCharactersView(recognizedCharacters: recognizedCharacters, charCounts: $charCounts, selectedCharacter: $selectedCharacter, clearDrawing: $clearDrawing)
                    .frame(width: UIScreen.main.bounds.width - 32)
                    .padding(16)
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
            .background(Color.black.opacity(0.9).ignoresSafeArea())
            .tabItem {
                Image(systemName: "pencil")
                Text("Draw")
            }
            
            VStack {
                 Text("Write Counts :3")
                     .font(.system(size: 24))
                     .fontWeight(.bold)
                     .padding(.top, 20)
                     .foregroundColor(.gray.opacity(0.9))
                 ScrollView {
                     LazyVGrid(
                         columns: [
                             GridItem(.flexible(), spacing: 50),
                             GridItem(.flexible())
                         ],
                         alignment: .leading,
                         spacing: 20,
                         content: {
                             ForEach(charCounts.sorted(by: { $0.value.1 > $1.value.1 }), id: \.key) { key, value in
                                 HStack {
                                     VStack {
                                         Text(key)
                                             .font(.title)
                                             .fontWeight(.bold)
                                             .padding(.leading, 10)
                                             .foregroundColor(.green)
                                         Text(value.0)
                                             .font(.system(size: 12))
                                             .foregroundColor(.gray.opacity(0.9))
                                     }
                                     Spacer()
                                     Text("\(value.1)")
                                         .font(.title)
                                         .fontWeight(.bold)
                                         .padding(.trailing, 10)
                                         .foregroundColor(.green)
                                 }
                                 .frame(maxWidth: .infinity)
                             }
                         }
                     )
                     .padding(.horizontal, 20)
                     .padding(.vertical, 10)
                 }
                 .background(Color.black)
                 .cornerRadius(10)
                 .shadow(radius: 10)
                 .padding(.horizontal, 16)
                 .padding(.bottom, 16)
             }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("List")
            }
            .background(Color.black.opacity(0.9).ignoresSafeArea())
        }
        .accentColor(.green)

    }
}



struct RecognizedCharactersView: View {
    
    var recognizedCharacters: [String]
    var jsVC: JSViewController = JSViewController()
    @Binding var charCounts: [String : (String, Int)]
    @Binding var selectedCharacter: String?
    @Binding var clearDrawing: Bool
    @State private var pinyinArray: [String] = []
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Recognized Characters")
                .font(.system(size: 16))
                .fontWeight(.bold)
                .foregroundColor(.gray.opacity(0.8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 24) {
                    ForEach(recognizedCharacters, id: \.self) { character in
                        CharacterButton(character: character, jsVC: jsVC, selectedCharacter: $selectedCharacter, pinyinArray: $pinyinArray, charCounts: $charCounts)
                    }
                }
            }
            .frame(height: 60)
        }
        .padding(.horizontal, 8)
    }
    
    func isClear() {
        if (clearDrawing) {
            selectedCharacter = nil
        }
    }
}

struct CharacterButton: View {
    let character: String
    let jsVC: JSViewController
    @Binding var selectedCharacter: String?
    @Binding var pinyinArray: [String]
    let englishModel = TranslateRemoteModel.translateRemoteModel(language: .english)
    let chineseModel = TranslateRemoteModel.translateRemoteModel(language: .chinese)
    lazy var translator = Translator.translator(options: TranslatorOptions(sourceLanguage: .chinese, targetLanguage: .english))
    @State var translatedText: String = ""
    @Binding var charCounts: [String : (String, Int)]
    
    var body: some View {
        Button(action: {
            jsVC.javascriptShit(input: character) { pinyinArray in
                self.pinyinArray = pinyinArray
                charCounts[character, default: (pinyinArray.joined(), 0)].1 += 1
            }
            var mutableSelf = self
            selectedCharacter = character
            
            mutableSelf.translateButtonTapped(character: character) { result in
                mutableSelf.translatedText = result
            }
        }) {
            VStack {
                Text(character)
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(selectedCharacter == character ? .green : .gray.opacity(0.85))
                if let selectedCharacter = selectedCharacter, selectedCharacter == character {
                    Text(pinyinArray.joined(separator: ", "))
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.85))
                    Text(translatedText)
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.85))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    mutating func translateButtonTapped(character: String, completion: @escaping (String) -> Void) {
        let conditions = ModelDownloadConditions(
            allowsCellularAccess: false,
            allowsBackgroundDownloading: true
        )
        ModelManager.modelManager().download(self.englishModel, conditions: conditions)
        ModelManager.modelManager().download(self.chineseModel, conditions: conditions)
        self.translator.downloadModelIfNeeded(with: conditions) { error in
            guard error == nil else {
                print("Error downloading the model: \(error!)")
                return
            }
        }
        self.translator.translate(character) { result, error in
            guard error == nil, let result = result else {
                print("Error translating the text: \(error!)")
                return
            }
            completion(result)
            }
        }
}


struct DrawingView: UIViewRepresentable {
    
    @Binding var clearDrawing: Bool
    @Binding var selectedCharacter: String?
    var delegate: DrawingViewDelegate
    
    func makeUIView(context: Context) -> DrawingUIView {
        let languageTag = "zh-Hani"
        let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: languageTag)
        if identifier == nil {
          // no model was found or the language tag couldn't be parsed, handle error.
        }
        let model = DigitalInkRecognitionModel.init(modelIdentifier: identifier!)
        let modelManager = ModelManager.modelManager()
        let conditions = ModelDownloadConditions.init(allowsCellularAccess: true,
                                               allowsBackgroundDownloading: true)
        modelManager.download(model, conditions: conditions)
        let options: DigitalInkRecognizerOptions = DigitalInkRecognizerOptions.init(model: model)
        let recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options)
        let view = DrawingUIView(recognizer: recognizer, delegate: delegate)
        return view
    }
    

    func updateUIView(_ uiView: DrawingUIView, context: Context) {
        if clearDrawing {
            uiView.clear()
            selectedCharacter = nil
            clearDrawing.toggle()
        }
    }
    
}

class DrawingUIView: UIView {
    private var lastPoint: CGPoint = .zero
    private var currentColor: UIColor = .systemGray3
    private var lineWidth: CGFloat = 5.0
    private var swiped = false
    private var strokes: [Stroke] = []
    private var points: [StrokePoint] = []
    private var recognizer: DigitalInkRecognizer?
    private var delegate: DrawingViewDelegate
    public var recognizedCharacters: [String] = []
    
    init(recognizer: DigitalInkRecognizer, delegate: DrawingViewDelegate) {
            self.delegate = delegate
            self.recognizer = recognizer
            super.init(frame: .zero)
        }
    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: self)
            let t = touch.timestamp
            points = [StrokePoint.init(x: Float(lastPoint.x),
                                         y: Float(lastPoint.y),
                                       t: Int(t * 1000.0))]
            drawLine(from:lastPoint, to:lastPoint)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: self)
            let t = touch.timestamp
              points.append(StrokePoint.init(x: Float(currentPoint.x),
                                             y: Float(currentPoint.y),
                                             t: Int(t * 1000.0)))
            drawLine(from: lastPoint, to: currentPoint)
            lastPoint = currentPoint
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if swiped {
            guard let touch = touches.first else {
                return
              }
            let currentPoint = touch.location(in: self)
            let t = touch.timestamp
              points.append(StrokePoint.init(x: Float(currentPoint.x),
                                             y: Float(currentPoint.y),
                                             t: Int(t * 1000.0)))
            drawLine(from: lastPoint, to: lastPoint)
            lastPoint = currentPoint
            strokes.append(Stroke.init(points: points))
            self.points = []
            doRecognition()
        }
    }
    
    func doRecognition() {
        let ink = Ink(strokes: strokes)
        recognizer?.recognize(
            ink: ink,
            completion: {
                (result: DigitalInkRecognitionResult?, error: Error?) in
                var alertTitle = ""
                var alertText = ""
                if let result = result {
                    alertTitle = "recognized these:"
                    alertText = result.candidates.map { $0.text }.joined(separator: "\n")
                    let characters = result.candidates.map({ $0.text })
                    self.delegate.didRecognizeCharacters(characters)
                }
                let alert = UIAlertController(title: alertTitle,
                                                message: alertText,
                                                preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK",
                                                style: UIAlertAction.Style.default,
                                                handler: nil))
            }
        )
    }

    private func drawLine(from startPoint: CGPoint, to endPoint: CGPoint) {
        UIGraphicsBeginImageContext(self.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        self.layer.render(in: context)

        context.move(to: startPoint)
        context.addLine(to: endPoint)

        context.setLineWidth(lineWidth)
        context.setStrokeColor(currentColor.cgColor)
        context.setLineCap(.round)
        context.strokePath()

        self.layer.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
    }
    
    func undo() {
        self.strokes.removeLast()
        doRecognition()
    }
    
    func clear() {
        self.layer.contents = nil
        self.strokes = []
        self.recognizedCharacters = []
        self.delegate.didRecognizeCharacters([])
    }
    
    
}

