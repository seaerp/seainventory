import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:sea_inventory/pages/inventory_info.dart';
import 'package:sea_inventory/pages/scanner.dart';
import 'package:sea_inventory/pages/test.dart';

import 'inventory_overview.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

//final orpc = OdooClient('https://home.seacorp.vn/');
final orpc = OdooClient('https://pilot.seateklab.vn/');

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List company_name = [];
  int company_id = 1;
  List stockWarehouse = [];
  List inventory = [];
  final controller = ScrollController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCompanyName();
      fetchCompany();
      getStockWarehouse();
      getInventory();
    });
  }

  Future<dynamic> fetchCompany() async {
    HttpOverrides.global = MyHttpOverrides();
    // await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    return orpc.callKw({
      'model': 'res.company',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [],
        'fields': ['id', 'name', 'email'],
      },
    });
  }

  getCompanyName() async {
    List company = await fetchCompany();
    company.sort((a, b) => a['id'].compareTo(b['id']));
    int first = company.first['id'];
    setState(() {
      company_name = company;
      company_id = first;
    });
  }

  getStockWarehouse() async {
    HttpOverrides.global = MyHttpOverrides();
    //await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    final stock = await orpc.callKw({
      'model': 'stock.warehouse',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['company_id', '=', company_id],
        ],
        'fields': ['id'],
      },
    });
    setState(() {
      stockWarehouse = stock;
    });
  }

  getInventory() async {
    setState(() {
      loading = false;
    });
    HttpOverrides.global = MyHttpOverrides();
    //await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    final inven = await orpc.callKw({
      'model': 'stock.picking.type',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['warehouse_id', '=', false],
        ],
        'fields': ['id', 'name', 'warehouse_id'],
      },
    });

    if (stockWarehouse.isNotEmpty) {
      for (int i = 0; i < stockWarehouse.length; i++) {
        final inv = await orpc.callKw({
          'model': 'stock.picking.type',
          'method': 'search_read',
          'args': [],
          'kwargs': {
            'domain': [
              // '|',
              ['warehouse_id', '=', stockWarehouse[i]['id']],
              //['warehouse_id', '=', false],
            ],
            'fields': ['id', 'name', 'warehouse_id'],
          },
        });
        //setState(() {
        inven.addAll(inv);
        //});
        setState(() {
          inventory = inven;
          loading = true;
        });
      }
    } else {
      setState(() {
        inventory = inven;
        loading = true;
      });
    }
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
          //builder: (context) =>const InventoryInfo(name: 'KCB/INT/00009'),
          builder: (context) => InventoryInfo(name: barcodeScanRes.toString()),
        ));
  }

  updateCompanyId(company_id) async {
    HttpOverrides.global = MyHttpOverrides();
    // await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
    await orpc.authenticate('HR_Company', 'khoa.huynh@seatek.vn', '1234');
    await orpc.callKw(
      {
        'model': 'res.users',
        'method': 'write',
        'args': [
          8,
          {
            'company_id': company_id,
          },
        ],
        'kwargs': {},
      }
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              ClipPath(
                  clipper: WaveClip(),
                  child: Container(
                      height: 105,
                      width: MediaQuery.of(context).size.width * 1,
                      color: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const Text('Inventory',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              )),
                          const Spacer(),
                          IconButton(
                              onPressed: () {
                                scanQR();
                              },
                              icon: const Icon(Icons.qr_code, color: Colors.white, size: 30))
                        ],
                      ))),
              if (company_name.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50, //background color of dropdown button
                          border: Border.all(
                              color: Colors.black38,
                              width: 1), //border of dropdown button
                          borderRadius: BorderRadius.circular(10), //border raiuds of dropdown button
                          boxShadow: const <BoxShadow>[
                            //apply shadow on Dropdown button
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.57), //shadow for button
                                blurRadius: 5) //blur radius of shadow
                          ]),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: DropdownButton(
                          dropdownColor: Colors.blueGrey.shade100,
                          menuMaxHeight: 400,
                          value: company_id,
                          isExpanded: true,
                          underline: Container(),
                          elevation: 16,
                          onChanged: (value) async {
                            setState(() {
                              company_id = value as int;
                            });
                            await updateCompanyId(value as int);
                            await getStockWarehouse();
                            await getInventory();
                          },
                          items: [
                            ...company_name.map((e) => DropdownMenuItem(
                                value: e['id'],
                                child: Container(
                                  child: Text(e['name']),
                                )
                              )
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                children: [
                  !loading
                      ? Container(
                          height: MediaQuery.of(context).size.height,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: inventory.isEmpty
                              ? SizedBox(
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
                                      const Text('Không có dữ liệu để hiển thị',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 2
                                        ),
                                      )
                                    ],
                                  )))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: inventory.length,
                                  controller: controller,
                                  itemBuilder: (BuildContext ctxt, int index) {
                                    return Container(
                                      color: index % 2 == 0
                                          ? const Color.fromARGB(255, 239, 241, 243)
                                          : const Color.fromARGB(255, 255, 255, 255),
                                      child: ListTile(
                                        title: Text(inventory[index]['name']),
                                        subtitle: inventory[index]['warehouse_id'] !=false
                                            ? Text(inventory[index]['warehouse_id'][1].toString())
                                            : const Text(''),
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    InventoryOverview(id: inventory[index]['id']),
                                              )
                                          );
                                        },
                                      ),
                                    );
                                  }),
                        )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaveClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = new Path();

    path.lineTo(0, size.height - 15);
    path.quadraticBezierTo( size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 / 4 * size.width, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
