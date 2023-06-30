import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beacon Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BeaconScanner(),
    );
  }
}

class BeaconScanner extends StatefulWidget {
  const BeaconScanner({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _BeaconScannerState createState() => _BeaconScannerState();
}

class _BeaconScannerState extends State<BeaconScanner> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 3));

    flutterBlue.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    flutterBlue.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon Scanner'),
      ),
      body: ListView.builder(
        itemCount: scanResults.length,
        itemBuilder: (context, index) {
          ScanResult scanResult = scanResults[index];
          int major = 0;
          int minor = 0;
          String uuid = '';
          // Check if device name exists
          // Check if the advertisement data contains the ManufacturerData
          if (scanResult.device.name.isNotEmpty &&
              scanResult.advertisementData.manufacturerData.isNotEmpty) {
            // Get the manufacturer data
            Map<int, List<int>> manufacturerData =
                scanResult.advertisementData.manufacturerData;
            // Check if the manufacturer data contains Apple's iBeacon format
            if (manufacturerData.containsKey(0x004C)) {
              // Get the iBeacon data
              List<int> ibeaconData = manufacturerData[0x004C]!;
              // Check if the iBeacon data is valid
              if (ibeaconData.length >= 22 &&
                  ibeaconData[0] == 0x02 &&
                  ibeaconData[1] == 0x15) {
                // Get the Major and Minor and UUID values
                major = (ibeaconData[18] << 8) + ibeaconData[19];
                minor = (ibeaconData[20] << 8) + ibeaconData[21];
                uuid = ibeaconData
                    .sublist(2, 18)
                    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
                    .join('')
                    .toUpperCase();
              }
            }

            return ListTile(
              title: Text(
                scanResult.device.name,
                style: const TextStyle(fontSize: 20),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uuid,
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text('MAC: ${scanResult.device.id}'),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Major: $major'),
                  Text('Minor: $minor'),
                ],
              ),
            );
          }

          // Return an empty container if device name does not exist
          return Container();
        },
      ),
    );
  }
}
