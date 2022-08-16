import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:sea_inventory/pages/inventory_info.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class InventoryOverview extends StatefulWidget {
  final int? id;
  const InventoryOverview({Key? key, this.id}) : super(key: key);

  @override
  State<InventoryOverview> createState() => _InventoryOverviewState();
}

class _InventoryOverviewState extends State<InventoryOverview> {
  //final orpc = OdooClient('http://10.0.2.2:8069/');
  final orpc = OdooClient('https://pilot.seateklab.vn/');
  List inventory = [];
  List stockWarehouse = [];
  final controller = ScrollController();
  int page = 0;
  int limit = 10;
  bool firstLoad = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (controller.position.atEdge) {
        final isTop = controller.position.pixels == 0;
        if (!isTop) {
          _scroll();
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchInventory(page);
    });
  }

  fetchInventory(page) async {
    HttpOverrides.global = MyHttpOverrides();
    //await orpc.authenticate('Seatek2206_01', 'khoa.huynh@seatek.vn', '1234');
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    final invs = await orpc.callKw({
      'model': 'stock.picking',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['picking_type_id', '=', widget.id]
        ],
        'fields': ['id', 'name', 'location_dest_id'],
        'limit': limit,
        'offset': page * limit,
      },
    });
    if (invs.isEmpty) {
      setState(() {
        firstLoad = false;
      });
    }
    if (invs.length < limit) {
      setState(() {
        inventory.addAll(invs);
        firstLoad = false;
      });
    } else {
      setState(() {
        inventory.addAll(invs);
        firstLoad = false;
      });
    }
  }

  void _scroll() async {
    setState(() {
      page = page + 1;
    });
    await fetchInventory(page);
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    if (!mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryInfo(name: barcodeScanRes.toString()),
          //builder: (context) =>const InventoryInfo(name: 'KCB/INT/00009'),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Inventory Overview"),
          actions: [
            IconButton(
                onPressed: () {
                  scanQR();
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) =>
                  //           const BarcodeScanner(id: 2835, name: 'KCB/INT/00009'),
                  //     ));
                },
                icon: const Icon(Icons.qr_code, color: Colors.white, size: 30))
          ],
        ),
        body: Container(
          child: firstLoad == true
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : inventory.isEmpty
                  ? Container(
                      height: MediaQuery.of(context).size.height * 1,
                      width: MediaQuery.of(context).size.width * 1,
                      child: Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.network(
                              'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1658376518/zvhinkjq5tg9y3wqpf7z.png',
                              height: 60),
                          const SizedBox(height: 20),
                          const Text(
                            'Không có dữ liệu để hiển thị',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 20),
                          )
                        ],
                      )))
                  : ListView.builder(
                      itemCount: inventory.length,
                      controller: controller,
                      itemBuilder: (BuildContext ctxt, int index) {
                        return Container(
                          color: index % 2 == 0
                              ? const Color.fromARGB(255, 239, 241, 243)
                              : const Color.fromARGB(255, 255, 255, 255),
                          child: ListTile(
                            title: Text(inventory[index]['name']),
                            subtitle: inventory[index]['location_dest_id'] ==
                                    false
                                ? const Text("")
                                : Text(inventory[index]['location_dest_id'][1]
                                    .toString()),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InventoryInfo(
                                      id: inventory[index]['id'],
                                      name: inventory[index]['name'],
                                    ),
                                  ));
                            },
                          ),
                        );
                      }),
        ));
  }
}
