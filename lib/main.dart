import 'dart:convert';
import 'dart:developer';
//saving the tag after eddidting it
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(MaterialApp(
    title: 'Home page',
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.dark,
    home: BlocProvider(
      create: (context) => PersonBloc(),
      child: const HomePage(),
    ),
  ));
}

const person1 = "http://127.0.0.1:5500/person2.json";
const person2 = "http://127.0.0.1:5500/person2.json";

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class Person {
  final String name;
  final int age;

  Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;

  @override
  String toString() => 'Person (name : $name, age: $age)';
}

@immutable
abstract class LoadAction {}

class PersonLoaderAction implements LoadAction {
  final String url;
  final PersonLoader loader;

  PersonLoaderAction({required this.url, required this.loader});
}

class FetchResults {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;

  FetchResults({
    required this.persons,
    required this.isRetrievedFromCache,
  });

  @override
  bool operator ==(covariant FetchResults other) =>
      persons.isEqualToIgnoringOrdering(other.persons) &&
      isRetrievedFromCache == other.isRetrievedFromCache;

  @override
  int get hashCode => Object.hashAll([persons, isRetrievedFromCache]);

  @override
  String toString() => 'Fetch results(person: $persons , '
      'isRetrievedFromCache:$isRetrievedFromCache';
}

typedef PersonLoader = Future<Iterable<Person>> Function(String url);

Future<Iterable<Person>> getPerson(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => jsonDecode(str) as List<dynamic>)
    .then(
      (list) => list.map((e) => Person.fromJson(e)),
    );

class PersonBloc extends Bloc<LoadAction, FetchResults?> {
  Map<String, Iterable<Person>> cache = {};
  PersonBloc() : super(null) {
    on<PersonLoaderAction>((event, emit) async {
      final url = event.url;

      if (cache.containsKey(url)) {
        final cachedPerson = cache[url];
        final result =
            FetchResults(persons: cachedPerson!, isRetrievedFromCache: true);
        print(result);
        emit(result);
      } else {
        final loader = event.loader;
        final loadedPerson = await loader(url);
        final result =
            FetchResults(persons: loadedPerson, isRetrievedFromCache: false);
        print(result);
        emit(result);
      }
    });
  }
}

extension Log on Object {
  void logon() => log(toString());
}

extension IsEqualToIgnoringOrdering<T> on Iterable<T> {
  bool isEqualToIgnoringOrdering(Iterable<T> other) {
    return length == other.length &&
        {...this}.intersection({...other}).length == length;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('eddited')),
      body: BlocBuilder<PersonBloc, FetchResults?>(
        builder: (context, state) {
          final persons = state?.persons;

          return Column(children: [
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      context.read<PersonBloc>().add(
                          PersonLoaderAction(url: person1, loader: getPerson));
                    },
                    child: const Text('Load perosn1')),
                TextButton(
                    onPressed: () {
                      context.read<PersonBloc>().add(
                          PersonLoaderAction(url: person2, loader: getPerson));
                    },
                    child: const Text('Load person2'))
              ],
            ),
            BlocBuilder<PersonBloc, FetchResults?>(
                buildWhen: (previous, current) =>
                    previous?.persons != current?.persons,
                builder: (context, state) {
                  if (state == null) {
                    return const SizedBox();
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: persons?.length,
                      itemBuilder: ((context, index) {
                        final person = persons![index];

                        return ListTile(
                          title: Text(person!.name),
                          subtitle: Text(person.age.toString()),
                        );
                      }),
                    ),
                  );
                })
          ]);
        },
      ),
    );
  }
}
