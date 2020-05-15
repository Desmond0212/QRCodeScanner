//
//  ViewController.swift
//  QRCodeReader_Desmond
//
//  Created by Desmond Wong on 15/05/2020.
//  Copyright © 2020 Desmond Wong. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate
{
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var btnMessage: UIButton!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var isUrlLink: Bool? = false
    var strUrlLink: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        btnMessage.isEnabled = true
        
        // Get the back-facing camera for capturing videos
        if #available(iOS 10.2, *)
        {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
            guard let captureDevice = deviceDiscoverySession.devices.first else {
                print("Failed to get the camera device")
                return
            }
            
            do
            {
                // Get an instance of the AVCaptureDeviceInput class using the previous device object.
                let input = try AVCaptureDeviceInput(device: captureDevice)

                // Set the input device on the capture session.
                captureSession.addInput(input)
                
                // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
                let captureMetadataOutput = AVCaptureMetadataOutput()
                captureSession.addOutput(captureMetadataOutput)
                
                // Set delegate and use the default dispatch queue to execute the call back
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                
                // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                
                // Move the message label and top bar to the front
                view.bringSubviewToFront(btnMessage)
                view.bringSubviewToFront(topBar)
                
                // Start video capture.
                captureSession.startRunning()
                
                // Initialize QR Code Frame to highlight the QR code
                qrCodeFrameView = UIView()

                if let qrCodeFrameView = qrCodeFrameView
                {
                    qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                    qrCodeFrameView.layer.borderWidth = 2
                    view.addSubview(qrCodeFrameView)
                    view.bringSubviewToFront(qrCodeFrameView)
                }
            }
            catch
            {
                // If any error occurs, simply print it out and don't continue any more.
                print(error)
                return
            }
        }
        else
        {
            // Fallback on earlier versions
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection)
    {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            btnMessage.setTitle("No QR code is detected", for: .normal)
            btnMessage.setTitleColor(.lightGray, for: .normal)
            btnMessage.isEnabled = false
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds

            if metadataObj.stringValue != nil
            {
                btnMessage.setTitle(metadataObj.stringValue, for: .normal)
                strUrlLink = metadataObj.stringValue
                
                if (verifyUrl(urlString: metadataObj.stringValue) == false)
                {
                    isUrlLink = false
                    btnMessage.setTitleColor(.lightGray, for: .normal)
                    btnMessage.isEnabled = false
                }
                else
                {
                    isUrlLink = true
                    btnMessage.isEnabled = true
                    btnMessage.setTitleColor(.systemBlue, for: .normal)
                }
            }
        }
        else
        {
            qrCodeFrameView?.frame = CGRect.zero
            btnMessage.setTitle("No QR code is detected", for: .normal)
            btnMessage.setTitleColor(.lightGray, for: .normal)
            btnMessage.isEnabled = false
        }
    }

    @IBAction func btnQRCodeOnClicked(_ sender: Any)
    {
        guard let url = URL(string: strUrlLink ?? "www.google.com") else { return }
        UIApplication.shared.open(url)
    }
    
    func verifyUrl (urlString: String?) -> Bool
    {
        if let urlString = urlString
        {
            if let url = NSURL(string: urlString)
            {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
}
