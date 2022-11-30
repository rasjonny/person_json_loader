import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:person_json_loader/main.dart';

const mockedPerson1 = [
  Person(name: "jo", age: 20),
  Person(name: "Heran", age: 30)
];
const mockedPerson2 = [
  Person(name: "jo", age: 20),
  Person(name: "Heran", age: 30)
];

Future<Iterable<Person>> getPersons1(String url) => Future.value(mockedPerson1);
Future<Iterable<Person>> getPersons2(String url) => Future.value(mockedPerson2);

void main() {
  group(
    "testing bloc",
    (() {
      late PersonBloc bloc;
      setUp(() {
        bloc = PersonBloc();
      });

      blocTest("testing bloc initial state", build: () {
        return bloc;
      }, verify: ((bloc) => bloc.state == null));
      blocTest('retreiveing person1',
          build: () {
            return bloc;
          },
          act: (bloc) {
            bloc.add(
                PersonLoaderAction(url: "dummy_url1", loader: getPersons1));
            bloc.add(
                PersonLoaderAction(url: "dummy_url1", loader: getPersons1));
          },
          expect: () => [
                FetchResults(
                    persons: mockedPerson1, isRetrievedFromCache: false),
                FetchResults(
                    persons: mockedPerson1, isRetrievedFromCache: false),
              ]);
      blocTest('retreiveing person2',
          build: () {
            return bloc;
          },
          act: (bloc) {
            bloc.add(
                PersonLoaderAction(url: "dummy_url2", loader: getPersons2));
          },
          expect: () => [
                FetchResults(
                    persons: mockedPerson2, isRetrievedFromCache: false),
              ]);
    }),
  );
}
