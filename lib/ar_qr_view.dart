import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARQRView extends StatefulWidget {
  final Function(String) onQRCodeScanned;

  const ARQRView({
    Key? key,
    required this.onQRCodeScanned,
  }) : super(key: key);

  @override
  State<ARQRView> createState() => _ARQRViewState();
}

class _ARQRViewState extends State<ARQRView> {
  ArCoreController? arCoreController;
  QRViewController? qrController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool showAR = false;

  @override
  void dispose() {
    arCoreController?.dispose();
    qrController?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        widget.onQRCodeScanned(scanData.code!);
        setState(() {
          showAR = true;
        });
        _initializeAR();
      }
    });
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    _addARContent(controller);
  }

  void _addARContent(ArCoreController controller) {
    final material = ArCoreMaterial(
      color: Colors.blue,
      metallic: 1.0,
    );
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.1,
    );
    final node = ArCoreNode(
      shape: sphere,
      position: vector.Vector3(0, 0, -1.5),
    );
    controller.addArCoreNode(node);
  }

  void _initializeAR() {
    qrController?.pauseCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!showAR)
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.white,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.height * 0.3,
            ),
          )
        else
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
          ),
        if (showAR)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              child: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  showAR = false;
                  qrController?.resumeCamera();
                });
              },
            ),
          ),
      ],
    );
  }
}