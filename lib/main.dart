import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // Inicializamos la localización de la fecha
  initializeDateFormatting().then((_) {
    runApp(MiAplicacion());
  });
}

class MiAplicacion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lanzamientos de SpaceX',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PantallaLanzamientos(),
    );
  }
}

class Lanzamiento {
  final String nombreMision;
  final DateTime fechaLanzamiento;
  final String estado;
  final String? imagenCohete;

  Lanzamiento({
    required this.nombreMision,
    required this.fechaLanzamiento,
    required this.estado,
    required this.imagenCohete,
  });

  factory Lanzamiento.fromJson(Map<String, dynamic> json) {
    return Lanzamiento(
      nombreMision: json['name'],
      fechaLanzamiento: DateTime.parse(json['date_utc']),
      estado: json['success'] == null
          ? 'Próximo'
          : (json['success'] ? 'Éxito' : 'Fallo'),
      imagenCohete: json['links']['patch']['large'],
    );
  }
}

class PantallaLanzamientos extends StatefulWidget {
  @override
  _PantallaLanzamientosState createState() => _PantallaLanzamientosState();
}

class _PantallaLanzamientosState extends State<PantallaLanzamientos> {
  late Future<List<Lanzamiento>> futurosLanzamientos;

  @override
  void initState() {
    super.initState();
    futurosLanzamientos = obtenerLanzamientos();
  }

  Future<List<Lanzamiento>> obtenerLanzamientos() async {
    final respuesta =
        await http.get(Uri.parse('https://api.spacexdata.com/v4/launches'));

    if (respuesta.statusCode == 200) {
      List<dynamic> datos = json.decode(respuesta.body);
      return datos.map((json) => Lanzamiento.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los lanzamientos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lanzamientos de SpaceX'),
      ),
      body: FutureBuilder<List<Lanzamiento>>(
        future: futurosLanzamientos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No se encontraron lanzamientos'));
          }

          List<Lanzamiento> lanzamientos = snapshot.data!;
          return ListView.builder(
            itemCount: lanzamientos.length,
            itemBuilder: (context, index) {
              return TarjetaLanzamiento(lanzamiento: lanzamientos[index]);
            },
          );
        },
      ),
    );
  }
}

class TarjetaLanzamiento extends StatelessWidget {
  final Lanzamiento lanzamiento;

  TarjetaLanzamiento({required this.lanzamiento});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lanzamiento.nombreMision,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
                'Fecha de lanzamiento: ${DateFormat.yMMMd().format(lanzamiento.fechaLanzamiento)}'),
            SizedBox(height: 10),
            Text('Estado: ${lanzamiento.estado}'),
            SizedBox(height: 10),
            lanzamiento.imagenCohete != null &&
                    lanzamiento.imagenCohete!.isNotEmpty
                ? Image.network(
                    lanzamiento.imagenCohete!,
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return Container(
                        height: 100,
                        color: Colors.grey,
                        child: Center(
                          child: Text('Imagen no disponible'),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 100,
                    color: Colors.grey,
                    child: Center(
                      child: Text('Imagen no disponible'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
