// ignore_for_file: unused_field

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class InventoryInfo extends StatefulWidget {
  final int? id;
  final String? name;
  const InventoryInfo({super.key, this.id, this.name});

  @override
  State<InventoryInfo> createState() => _InventoryInfoState();
}

class _InventoryInfoState extends State<InventoryInfo>
    with TickerProviderStateMixin {
  final orpc = OdooClient('http://10.0.2.2:8069/');
  List inventory = [];
  late TabController _tabController;
  List move_ids_without_package = [];
  List backorder_ids = [];
  List return_ids = [];
  bool show_operations = false;

  List listOperations = [];
  List listBackorder = [];
  List listReturn = [];

  bool isWatchingInfo = true;
  bool isWatchingOperations = false;
  bool isWatchingReturn = false;
  bool isWatchingDelivery = false;
  bool isWatchingNote = false;
  bool isWatchingBackOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInventoryOverview();
      _tabController = TabController(length: 3, vsync: this);
    });
  }

  Future<dynamic> fetchInventoryOverview() async {
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('Seatek2206_01', 'khoa.huynh@seatek.vn', '123456');
    return orpc.callKw({
      'model': 'stock.picking',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['name', '=', widget.name]
        ],
        'fields': [
          'id',
          'name',
          'partner_id',
          'location_id',
          'location_dest_id',
          'picking_type_id',
          'scheduled_date',
          'date_done',
          'origin',
          'move_ids_without_package',
          'backorder_ids',
          'show_operations',
          'returned_ids',
          'move_type',
          'carrier_id',
          'carrier_tracking_ref',
          'company_id',
          'group_id',
          'client_order_ref',
          'priority',
          'weight',
          'shipping_weight',
          'note',
          'weight_uom_id'
        ],
      },
    });
  }

  getInventoryOverview() async {
    List inv = await fetchInventoryOverview();
    //company.sort((a, b) => a['id'].compareTo(b['id']));
    for (var element in inv) {
      final move = element['move_ids_without_package'];
      final backorder = element['backorder_ids'];
      final returns = element['returned_ids'];
      final show = element['show_operations'];
      setState(() {
        move_ids_without_package = move;
        backorder_ids = backorder;
        return_ids = returns;
        show_operations = show;
      });
    }
    setState(() {
      inventory = inv;
    });

    // print(move_ids_without_package);
    // print(backorder_ids);
    // print(return_ids);
    // print(show_operations);

    if (move_ids_without_package.isNotEmpty) getOperation();

    if (backorder_ids.isNotEmpty) getBackorder();

    if (return_ids.isNotEmpty) getReturn();
  }

  getOperation() async {
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('Seatek2206_01', 'khoa.huynh@seatek.vn', '123456');
    for (int i = 0; i < move_ids_without_package.length; i++) {
      final move = await orpc.callKw({
        'model': 'stock.move',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            // '|',
            ['id', '=', move_ids_without_package[i]],
            //['warehouse_id', '=', false],
          ],
          'fields': [
            'id',
            'name',
            'product_uom_qty',
            'quantity_done',
            'remarks',
            'product_uom'
          ],
        },
      });
      setState(() {
        listOperations.addAll(move);
      });
    }
  }

  getBackorder() async {
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('Seatek2206_01', 'khoa.huynh@seatek.vn', '123456');
    for (int i = 0; i < backorder_ids.length; i++) {
      final inv = await orpc.callKw({
        'model': 'stock.picking',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            ['id', '=', backorder_ids[i]],
          ],
          'fields': [
            'id',
            'name',
            'location_dest_id',
            'partner_id',
            'client_order_ref',
            'scheduled_date',
            'origin',
            'backorder_id',
            'state'
          ],
        },
      });
      setState(() {
        listBackorder.addAll(inv);
      });
    }
  }

  getReturn() async {
    HttpOverrides.global = MyHttpOverrides();
    await orpc.authenticate('Seatek2206_01', 'khoa.huynh@seatek.vn', '123456');
    for (int i = 0; i < return_ids.length; i++) {
      final inv = await orpc.callKw({
        'model': 'stock.picking',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            // '|',
            ['id', '=', return_ids[i]],
            //['warehouse_id', '=', false],
          ],
          'fields': [
            'id',
            'name',
            'location_dest_id',
            'partner_id',
            'client_order_ref',
            'scheduled_date',
            'origin',
            'backorder_id',
            'state'
          ],
        },
      });
      setState(() {
        listReturn.addAll(inv);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name.toString()),
      ),
      body: SingleChildScrollView(
          child: Container(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            ...inventory.map((e) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isWatchingInfo = !isWatchingInfo;
                          });
                        },
                        child: Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDB827),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(.3),
                                  blurRadius: 10.0, // soften the shadow
                                  spreadRadius: 0.0, //extend the shadow
                                  offset: const Offset(
                                    3.0, // Move to right 10  horizontally
                                    3.0, // Move to bottom 10 Vertically
                                  ),
                                )
                              ],
                            ),
                            child: Row(children: [
                              Image.network(
                                'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649657800/letter_cuoprh.png',
                                height: 50,
                              ),
                              const SizedBox(width: 20),
                              const Text('Information',
                                  style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600))
                            ])),
                      ),
                    ),
                    isWatchingInfo
                        ? Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: Table(
                              border: TableBorder.all(
                                color: Colors.lightBlueAccent,
                                width: 1,
                                style: BorderStyle.solid,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(5),
                              },
                              children: [
                                TableRow(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Partner',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: e['partner_id'] == false
                                        ? const Text('')
                                        : Text(
                                            e['partner_id'][1],
                                          ),
                                  ),
                                ]),
                                TableRow(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Source Location',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: e['location_id'] == false
                                        ? const Text('')
                                        : Text(
                                            e['location_id'][1],
                                          ),
                                  ),
                                ]),
                                TableRow(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Destination Location',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: e['location_dest_id'] == false
                                        ? const Text('')
                                        : Text(
                                            e['location_dest_id'][1],
                                          ),
                                  ),
                                ]),
                                TableRow(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Operation Type',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: e['picking_type_id'] == false
                                        ? const Text('')
                                        : Text(
                                            e['picking_type_id'][1],
                                          ),
                                  ),
                                ]),
                                TableRow(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Scheduled Date',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: e['scheduled_date'] == false
                                        ? const Text('')
                                        : Text(
                                            e['scheduled_date'].toString(),
                                          ),
                                  ),
                                ]),
                                TableRow(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Effective Date',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: e['date_done'] == false
                                        ? const Text('')
                                        : Text(
                                            e['date_done'].toString(),
                                          ),
                                  ),
                                ]),
                                TableRow(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Source Document',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: e['origin'] == false
                                        ? const Text('')
                                        : Text(
                                            e['origin'].toString(),
                                          ),
                                  ),
                                ]),
                              ],
                            ),
                          )
                        : const SizedBox(),
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isWatchingOperations = !isWatchingOperations;
                            });
                          },
                          child: Container(
                              height: 70,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF343A40),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(.3),
                                    blurRadius: 10.0, // soften the shadow
                                    spreadRadius: 0.0, //extend the shadow
                                    offset: const Offset(
                                      3.0, // Move to right 10  horizontally
                                      3.0, // Move to bottom 10 Vertically
                                    ),
                                  )
                                ],
                              ),
                              child: Row(children: [
                                Image.network(
                                  'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649657800/folder_1_a35vck.png',
                                  height: 40,
                                ),
                                const SizedBox(width: 20),
                                const Text('Operations',
                                    style: TextStyle(
                                        fontSize: 25,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600))
                              ])),
                        )),
                    isWatchingOperations && listOperations.isNotEmpty
                        ? Column(children: [
                            Container(
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: Column(
                                  children: [
                                    ...listOperations.map((pro) => Column(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.only(top: 10),
                                              child: Table(
                                                border: TableBorder.all(
                                                  color: Colors.lightBlueAccent,
                                                  width: 1,
                                                  style: BorderStyle.solid,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                columnWidths: const {
                                                  0: FlexColumnWidth(2),
                                                  1: FlexColumnWidth(5),
                                                },
                                                children: [
                                                  TableRow(children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: const Text(
                                                        'Product',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                    Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: Text(pro['name']
                                                            .toString())),
                                                  ]),
                                                  TableRow(children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: const Text(
                                                        'Initial Demand',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                    Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: pro['product_uom_qty'] !=
                                                                false
                                                            ? Text(
                                                                pro['product_uom_qty']
                                                                    .toString())
                                                            : Text('')),
                                                  ]),
                                                  TableRow(children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: const Text(
                                                        'Done',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                    Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: pro['quantity_done'] !=
                                                                false
                                                            ? Text(
                                                                pro['quantity_done']
                                                                    .toString())
                                                            : Text('')),
                                                  ]),
                                                  TableRow(children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: const Text(
                                                        'Remarks',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                    Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: pro['remarks'] !=
                                                                false
                                                            ? Text(
                                                                pro['remarks']
                                                                    .toString())
                                                            : Text('')),
                                                  ]),
                                                  TableRow(children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: const Text(
                                                        'Unit of Measure',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                    Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: pro['product_uom'] !=
                                                                false
                                                            ? Text(
                                                                pro['product_uom']
                                                                        [1]
                                                                    .toString())
                                                            : Text('')),
                                                  ]),
                                                ],
                                              ),
                                            )
                                          ],
                                        ))
                                  ],
                                )),
                          ])
                        : const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isWatchingDelivery = !isWatchingDelivery;
                          });
                        },
                        child: Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF247291),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(.3),
                                  blurRadius: 10.0, // soften the shadow
                                  spreadRadius: 0.0, //extend the shadow
                                  offset: const Offset(
                                    3.0, // Move to right 10  horizontally
                                    3.0, // Move to bottom 10 Vertically
                                  ),
                                )
                              ],
                            ),
                            child: Row(children: [
                              Image.network(
                                'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1658215048/ty3eybk1gcz2bcdjlx1v.png',
                                height: 50,
                              ),
                              const SizedBox(width: 20),
                              const Text('Additional Information',
                                  style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600))
                            ])),
                      ),
                    ),
                    isWatchingDelivery
                        ? Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: Column(
                              children: [
                                Container(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            5, 0, 5, 0),
                                        child: Table(
                                          border: TableBorder.all(
                                            color: Colors.lightBlueAccent,
                                            width: 1,
                                            style: BorderStyle.solid,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          columnWidths: const {
                                            0: FlexColumnWidth(2),
                                            1: FlexColumnWidth(5),
                                          },
                                          children: [
                                            TableRow(children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: const Text(
                                                  'Shipping Policy',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: e['move_type'] == false
                                                      ? Text('')
                                                      : e['move_type'] ==
                                                              'direct'
                                                          ? Text(
                                                              'As soon as possible')
                                                          : Text(
                                                              'When all products are ready'))
                                            ]),
                                            TableRow(children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: const Text(
                                                  'Company',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: e['company_id'] == false
                                                    ? const Text('')
                                                    : Text(
                                                        e['company_id'][1],
                                                      ),
                                              ),
                                            ]),
                                            TableRow(children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: const Text(
                                                  'Procurement Group',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: e['group_id'] == false
                                                    ? const Text('')
                                                    : Text(
                                                        e['group_id'][1],
                                                      ),
                                              ),
                                            ]),
                                            TableRow(children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: const Text(
                                                  'Customer Reference',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: e['client_order_ref'] ==
                                                        false
                                                    ? const Text('')
                                                    : Text(
                                                        e['client_order_ref']
                                                            [1],
                                                      ),
                                              ),
                                            ]),
                                            TableRow(children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: const Text(
                                                  'Priority',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              if (e['priority'] != false)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: e['priority'] == '1'
                                                      ? const Text('Normal')
                                                      : e['priority'] == '0'
                                                          ? const Text(
                                                              'Not urgent')
                                                          : e['priority'] == '2'
                                                              ? const Text(
                                                                  'Urgent')
                                                              : const Text(
                                                                  'Very Urgent'),
                                                ),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                  child: const Text(
                                    "Delivery Information",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Table(
                                    border: TableBorder.all(
                                      color: Colors.lightBlueAccent,
                                      width: 1,
                                      style: BorderStyle.solid,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(5),
                                    },
                                    children: [
                                      TableRow(children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: const Text(
                                            'Carrier',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Container(
                                            padding: const EdgeInsets.all(10),
                                            child: e['carrier_id'] == false
                                                ? Text('')
                                                : Text(e['carrier_id'][1]
                                                    .toString()))
                                      ]),
                                      TableRow(children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: const Text(
                                            'Tracking Reference',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: e['carrier_tracking_ref'] ==
                                                  false
                                              ? const Text('')
                                              : Text(
                                                  e['carrier_tracking_ref'][1],
                                                ),
                                        ),
                                      ]),
                                      TableRow(children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: const Text(
                                            'Weight',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text('${e['weight']} ' +
                                              e['weight_uom_id'][1]),
                                        ),
                                      ]),
                                      TableRow(children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: const Text(
                                            'Weight for Shipping',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            e['shipping_weight'].toString(),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(height: 0),
                    if (e['note'] != false)
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 10),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    isWatchingNote = !isWatchingNote;
                                  });
                                },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 44, 42, 42)
                                          .withOpacity(.3),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(.3),
                                          blurRadius: 10.0, // soften the shadow
                                          spreadRadius: 0.0, //extend the shadow
                                          offset: const Offset(
                                            3.0, // Move to right 10  horizontally
                                            3.0, // Move to bottom 10 Vertically
                                          ),
                                        )
                                      ],
                                    ),
                                    child: Row(children: [
                                      Image.network(
                                        'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1650697125/xaoib7p8jcqna1gvgu5m.png',
                                        height: 50,
                                      ),
                                      const SizedBox(width: 20),
                                      const Text('Note',
                                          style: TextStyle(
                                              fontSize: 22,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600))
                                    ])),
                              ),
                            ),
                            isWatchingNote
                                ? Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    alignment: Alignment.topLeft,
                                    child: Text(e['note'].toString()),
                                  )
                                : SizedBox()
                          ],
                        ),
                      ),
                    if (listBackorder.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isWatchingBackOrder = !isWatchingBackOrder;
                            });
                          },
                          child: Container(
                              height: 70,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 36, 122, 99),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(.3),
                                    blurRadius: 10.0, // soften the shadow
                                    spreadRadius: 0.0, //extend the shadow
                                    offset: const Offset(
                                      3.0, // Move to right 10  horizontally
                                      3.0, // Move to bottom 10 Vertically
                                    ),
                                  )
                                ],
                              ),
                              child: Row(children: [
                                Image.network(
                                  'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1658215048/ty3eybk1gcz2bcdjlx1v.png',
                                  height: 50,
                                ),
                                const SizedBox(width: 20),
                                const Text('Backoders',
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600))
                              ])),
                        ),
                      ),
                    isWatchingBackOrder
                        ? Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: Column(
                              children: [
                                ...listBackorder.map(
                                  (back) => Container(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Table(
                                      border: TableBorder.all(
                                        color: Colors.lightBlueAccent,
                                        width: 1,
                                        style: BorderStyle.solid,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      columnWidths: const {
                                        0: FlexColumnWidth(2),
                                        1: FlexColumnWidth(5),
                                      },
                                      children: [
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Reference',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                              padding: const EdgeInsets.all(10),
                                              child: back['name'] == false
                                                  ? Text('')
                                                  : Text(
                                                      back['name'].toString()))
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Destination Location',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: back['location_dest_id'] ==
                                                    false
                                                ? const Text('')
                                                : Text(
                                                    back['location_dest_id'][1],
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Partner',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: back['partner_id'] == false
                                                ? const Text('')
                                                : Text(
                                                    back['partner_id'][1],
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Customer Reference',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: back['client_order_ref'] ==
                                                    false
                                                ? const Text('')
                                                : Text(
                                                    back['client_order_ref'][1],
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Scheduled Date',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child:
                                                back['scheduled_date'] == false
                                                    ? const Text('')
                                                    : Text(
                                                        back['scheduled_date']
                                                            .toString(),
                                                      ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Source Document',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: back['origin'] == false
                                                ? const Text('')
                                                : Text(
                                                    back['origin'].toString(),
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Back Order of',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: back['backorder_id'] == false
                                                ? const Text('')
                                                : Text(
                                                    back['backorder_id'][1]
                                                        .toString(),
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Status',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: back['state'] == false
                                                ? const Text('')
                                                : back['state'] == 'draft'
                                                    ? Text('Draft')
                                                    : back['state'] == 'waiting'
                                                        ? const Text(
                                                            'Waiting Another Operation')
                                                        : back['state'] ==
                                                                'confirmed'
                                                            ? Text('Waiting')
                                                            : back['state'] ==
                                                                    'assigned'
                                                                ? Text('Ready')
                                                                : back['state'] ==
                                                                        'done'
                                                                    ? Text(
                                                                        'Done')
                                                                    : const Text(
                                                                        'Cancelled'),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        : const SizedBox(),
                    if (listReturn.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isWatchingReturn = !isWatchingReturn;
                            });
                          },
                          child: Container(
                              height: 70,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 36, 122, 99),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(.3),
                                    blurRadius: 10.0, // soften the shadow
                                    spreadRadius: 0.0, //extend the shadow
                                    offset: const Offset(
                                      3.0, // Move to right 10  horizontally
                                      3.0, // Move to bottom 10 Vertically
                                    ),
                                  )
                                ],
                              ),
                              child: Row(children: [
                                Image.network(
                                  'https://res.cloudinary.com/dhrpdnd8m/image/upload/v1649844285/chat_2_x7962a.png',
                                  height: 50,
                                ),
                                const SizedBox(width: 20),
                                const Text('Returns',
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600))
                              ])),
                        ),
                      ),
                    isWatchingReturn
                        ? Container(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              children: [
                                ...listReturn.map(
                                  (rtn) => Container(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Table(
                                      border: TableBorder.all(
                                        color: Colors.lightBlueAccent,
                                        width: 1,
                                        style: BorderStyle.solid,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      columnWidths: const {
                                        0: FlexColumnWidth(2),
                                        1: FlexColumnWidth(5),
                                      },
                                      children: [
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Reference',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                              padding: const EdgeInsets.all(10),
                                              child: rtn['name'] == false
                                                  ? Text('')
                                                  : Text(
                                                      rtn['name'].toString()))
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Destination Location',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: rtn['location_dest_id'] ==
                                                    false
                                                ? const Text('')
                                                : Text(
                                                    rtn['location_dest_id'][1],
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Partner',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: rtn['partner_id'] == false
                                                ? const Text('')
                                                : Text(
                                                    rtn['partner_id'][1],
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Customer Reference',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: rtn['client_order_ref'] ==
                                                    false
                                                ? const Text('')
                                                : Text(
                                                    rtn['client_order_ref'][1],
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Scheduled Date',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child:
                                                rtn['scheduled_date'] == false
                                                    ? const Text('')
                                                    : Text(
                                                        rtn['scheduled_date']
                                                            .toString(),
                                                      ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Source Document',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: rtn['origin'] == false
                                                ? const Text('')
                                                : Text(
                                                    rtn['origin'].toString(),
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Back Order of',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: rtn['backorder_id'] == false
                                                ? const Text('')
                                                : Text(
                                                    rtn['backorder_id'][1]
                                                        .toString(),
                                                  ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: const Text(
                                              'Status',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            child: rtn['state'] == false
                                                ? const Text('')
                                                : rtn['state'] == 'draft'
                                                    ? Text('Draft')
                                                    : rtn['state'] == 'waiting'
                                                        ? Text(
                                                            'Waiting Another Operation')
                                                        : rtn['state'] ==
                                                                'confirmed'
                                                            ? Text('Waiting')
                                                            : rtn['state'] ==
                                                                    'assigned'
                                                                ? Text('Ready')
                                                                : rtn['state'] ==
                                                                        'done'
                                                                    ? Text(
                                                                        'Done')
                                                                    : Text(
                                                                        'Cancelled'),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        : const SizedBox(),
                  ],
                ))
          ],
        ),
      )),
    );
  }

  // Widget widgetPriority(String priority){
  //   return Container(
  //     padding: const EdgeInsets.all(10),
  //     child: Column(
  //       children: [
  //         if(priority == '0')...[
  //           Text("Not urgent")
  //         ]else if(priority == '1')...[
  //           Text('Normal')
  //         ]else if(priority == '2')...[
  //           Text('Urgent')
  //         ]else...[
  //           Text('Very Urgent')
  //         ]
  //       ],
  //     ),
  //   );
  // }
}
