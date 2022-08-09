import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:sea_inventory/pages/test.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

final orpc = OdooClient('https://home.seacorp.vn/');

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
    await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
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
    await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
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
    print(stockWarehouse);
  }

  getInventory() async {
    print(1111);
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('opensea12pro', 'appconnect', 'xMNgdAQM');
    //print(inventory);
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
        });
      }
    }
    else{
      print(inven);
      setState(() {
        inventory = inven;
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
          builder: (context) => Test(id: int.parse(barcodeScanRes)),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Inventory'),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
              onPressed: () {
                scanQR();
              },
              icon: const Icon(Icons.qr_code, color: Colors.white, size: 30))
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.deepPurple
                            .shade50, //background color of dropdown button
                        border: Border.all(
                            color: Colors.black38,
                            width: 1), //border of dropdown button
                        borderRadius: BorderRadius.circular(
                            10), //border raiuds of dropdown button
                        boxShadow: const <BoxShadow>[
                          //apply shadow on Dropdown button
                          BoxShadow(
                              color: Color.fromRGBO(
                                  0, 0, 0, 0.57), //shadow for button
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
                        onChanged: (value) async{
                          setState(() {
                            company_id = value as int;
                          });
                          await getStockWarehouse();
                          await getInventory();
                        },
                        items: [
                          ...company_name.map((e) => DropdownMenuItem(
                              value: e['id'],
                              child: Container(
                                child: Text(e['name']),
                              )))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: inventory.isEmpty
                    ? const Center(child: Text("Data not found!! Hic hic"),)
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
                              subtitle: inventory[index]['warehouse_id'] !=
                                      false
                                  ? Text(inventory[index]['warehouse_id'][1]
                                      .toString())
                                  : const Text(''),
                              onTap: () {
                                // Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) =>
                                //           InventoryOverview(
                                //               id: fixedInventories[
                                //                   index]['id']),
                                //     ));
                              },
                            ),
                          );
                        }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
