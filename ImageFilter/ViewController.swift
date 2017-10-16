//
//  ViewController.swift
//  ImageFilter
//
//  Created by Carlos Rodolfo Santos on 09/10/2017.
//  Copyright © 2017 Carlos Rodolfo Santos. All rights reserved.
//

import UIKit


extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    /// Returns the data for the specified image in PNG format
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the PNG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    var png: Data? { return UIImagePNGRepresentation(self) }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ quality: JPEGQuality) -> Data? {
        return UIImageJPEGRepresentation(self, quality.rawValue)
    }
}

extension UIImage {
    struct RotationOptions: OptionSet {
        let rawValue: Int
        
        static let flipOnVerticalAxis = RotationOptions(rawValue: 1)
        static let flipOnHorizontalAxis = RotationOptions(rawValue: 2)
    }
    
    func rotated(by rotationAngle: Measurement<UnitAngle>, options: RotationOptions = []) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let rotationInRadians = CGFloat(rotationAngle.converted(to: .radians).value)
        let transform = CGAffineTransform(rotationAngle: rotationInRadians)
        var rect = CGRect(origin: .zero, size: self.size).applying(transform)
        rect.origin = .zero
        
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: rect.midX, y: rect.midY)
            renderContext.cgContext.rotate(by: rotationInRadians)
            
            let x = options.contains(.flipOnVerticalAxis) ? -1.0 : 1.0
            let y = options.contains(.flipOnHorizontalAxis) ? 1.0 : -1.0
            renderContext.cgContext.scaleBy(x: CGFloat(x), y: CGFloat(y))
            
            let drawRect = CGRect(origin: CGPoint(x: -self.size.width/2, y: -self.size.height/2), size: self.size)
            renderContext.cgContext.draw(cgImage, in: drawRect)
        }
    }
}

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let viewTop: UIView = {
        let viewTop = UIView()
        viewTop.translatesAutoresizingMaskIntoConstraints = false
        viewTop.backgroundColor = .lightGray
        return viewTop
    }()
    
    var imageOri: UIImage!
    
    let imageMain: UIImageView = {
        let imageMain = UIImageView()
        imageMain.translatesAutoresizingMaskIntoConstraints = false
        imageMain.image = #imageLiteral(resourceName: "tigre")
        imageMain.contentMode = .scaleAspectFill
        imageMain.clipsToBounds = true
        return imageMain
    }()
    
    let picker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    
    let btTakePhoto: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle("Capturar Foto", for: .normal)
        bt.setTitleColor(.white, for: .normal)
        bt.backgroundColor = .blue
        return bt
    }()
    
    let btSalvar: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle("Salvar", for: .normal)
        bt.setTitleColor(.white, for: .normal)
        bt.backgroundColor = .green
        bt.titleLabel?.textColor = .white
        return bt
    }()
    
    let btPagar: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle("Pagar", for: .normal)
        bt.setTitleColor(.white, for: .normal)
        bt.backgroundColor = .green
        bt.titleLabel?.textColor = .white
        return bt
    }()
    
    var imagePicker: UIImagePickerController!
    
    let options: [String] = ["Original", "CIPhotoEffectChrome", "CISepiaTone", "CIPhotoEffectTransfer", "CIPhotoEffectTonal", "CIPhotoEffectProcess", "CIPhotoEffectNoir", "CIPhotoEffectInstant", "CIPhotoEffectFade"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(viewTop)
        viewTop.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        viewTop.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        viewTop.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        viewTop.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        view.addSubview(imageMain)
        imageMain.topAnchor.constraint(equalTo: viewTop.bottomAnchor, constant: 20).isActive = true
        imageMain.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        imageMain.widthAnchor.constraint(equalToConstant: 200).isActive = true
        imageMain.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        
        view.addSubview(picker)
        picker.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        picker.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        picker.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        //picker.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        view.addSubview(btSalvar)
        btSalvar.topAnchor.constraint(equalTo: imageMain.bottomAnchor, constant: 8).isActive = true
        btSalvar.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        btSalvar.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btSalvar.heightAnchor.constraint(equalToConstant: 35).isActive = true
        btSalvar.addTarget(self, action: #selector(sendImage(_:)), for: .touchUpInside)
        
        view.addSubview(btTakePhoto)
        btTakePhoto.topAnchor.constraint(equalTo: btSalvar.bottomAnchor, constant: 8).isActive = true
        btTakePhoto.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        btTakePhoto.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btTakePhoto.heightAnchor.constraint(equalToConstant: 35).isActive = true
        btTakePhoto.addTarget(self, action: #selector(takePhoto(_:)), for: .touchUpInside)
        
        
        view.addSubview(btPagar)
        btPagar.topAnchor.constraint(equalTo: btTakePhoto.bottomAnchor, constant: 8).isActive = true
        btPagar.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        btPagar.widthAnchor.constraint(equalToConstant: 100).isActive = true
        btPagar.heightAnchor.constraint(equalToConstant: 35).isActive = true
        btPagar.addTarget(self, action: #selector(sendPagamento(_:)), for: .touchUpInside)
        
        picker.delegate = self
        picker.dataSource = self
        
        imageOri = #imageLiteral(resourceName: "tigre")
        
        
        
        
        //imageMain.image = UIImage(ciImage: filter.outputImage!)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @objc func sendImage(_ sender: UIButton) {
        UploadRequest()
    }
    
    @objc func takePhoto(_ sender: UIButton) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        imageMain.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        imageMain.image = imageMain.image?.resized(toWidth: 72.0)
        
        /*if let imageData = imageMain.image?.jpeg(.lowest) {
            imageMain.image = UIImage(data: imageData) 
        }*/
        
        imageOri = imageMain.image
    }
    
    func setFilterImage(row: Int) {
        
        if row > 0 {
            imageMain.image = imageOri
            let ciContext = CIContext(options: nil)
            let beginImage = CIImage(image: imageMain.image!)
            let filter = CIFilter(name: options[row])!
            filter.setDefaults()
            
            filter.setValue(beginImage, forKey: kCIInputImageKey)
            //filter.setValue(1, forKey: kCIInputIntensityKey)
            let filterImageData = filter.value(forKey: kCIOutputImageKey) as! CIImage
            let filterImageRef = ciContext.createCGImage(filterImageData, from: filterImageData.extent)
            
            let imageButton = UIImage(cgImage: filterImageRef!).rotated(by: Measurement(value: 0.0, unit: .degrees))
            
            
            imageMain.image = imageButton
        } else {
            
            imageMain.image = imageOri
            
        }
        
        
    }
    
    func UploadRequest()
    {
        //let url = URL(string: "http://192.168.0.54/web/_rodolfo/ajax/setAvaliacao.php")
        
        let url = URL(string: "http://192.168.0.52/temps/salvar_img/setAvaliacao.php")
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if (imageMain.image == nil)
        {
            return
        }
        
        let image_data = UIImagePNGRepresentation(imageMain.image!)
        
        if(image_data == nil)
        {
            return
        }
        
        let body = NSMutableData()
        
        let fname = "test.png"
        let mimetype = "image/png"
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"test\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("hi\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(image_data!)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        request.httpBody = body as Data
        let session = URLSession.shared
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {            (
            data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            
            print(dataString)
        }
        task.resume()
    }
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(UUID().uuidString)"
    }
    
    
    @objc func sendPagamento(_ sender: UIButton) {
        efetuarPagamento()
    }
    
    func efetuarPagamento() {
        let headers = [
            "merchantid": "03d9b59f-37f1-490f-8b45-7272fbca7773",
            "content-type": "application/json",
            "merchantkey": "XIGDULRKRCICNUXYNAWNZGURKHGRPWBCJTAQUODL",
            "cache-control": "no-cache",
            "postman-token": "616f37d8-018b-b29b-3b52-0d0020365261"
        ]
        let parameters = [
            "MerchantOrderId": "2014111703",
            "Payment": [
                "Type": "CreditCard",
                "Amount": 15700,
                "Installments": 1,
                "SoftDescriptor": "123456789ABCD",
                "CreditCard": [
                    "CardNumber": "4551870000000183",
                    "Holder": "Teste Holder",
                    "ExpirationDate": "12/2021",
                    "SecurityCode": "123",
                    "Brand": "Visa"
                ]
            ]
            ] as [String : Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://apisandbox.cieloecommerce.cielo.com.br/1/sales")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as! Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                
                print(dataString)
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
        })
        
        dataTask.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(options[row])
        setFilterImage(row: row)
    }
    
    
    


}

