import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Home page',
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: BlocProvider(
        create: (context) => AppBloc(
          loginProtocol: LoginApi(),
          notesProtocol: NotesApi(),
        ),
        child: const HomePage(),
      ),
    ),
  );
}

class LoginHandle {
  final String token;

  LoginHandle({
    required this.token,
  });
  LoginHandle.foo() : token = 'real token';

  @override
  bool operator ==(covariant LoginHandle other) => other.token == token;

  @override
  int get hashCode => token.hashCode;
}

abstract class LoginProtocol {
  LoginProtocol();
  Future<LoginHandle?> login({required String email, required String password});
}

class LoginApi extends LoginProtocol {
  @override
  Future<LoginHandle?> login({
    required String email,
    required String password,
  }) {
    return Future.delayed(
      const Duration(seconds: 2),
      () => email == 'jo@email.com' && password == 'asdfjkl'
          ? LoginHandle.foo()
          : null,
    );
  }
}

enum Errors {
  invalidHandle,
}

abstract class NotesProtocol {
  NotesProtocol();

  Future<Iterable<Note>?> notes({required LoginHandle? handle});
}

class Note {
  final String title;

  Note({
    required this.title,
  });
}

final mockedNotes = Iterable.generate(
  4,
  ((index) => Note(title: 'notes ${index + 1},)')),
);

class NotesApi extends NotesProtocol {
  // const NotesApi._sharedInstance();
  //  static const _shared = NotesApi._sharedInstance();
  // factory NotesApi() => _shared;
  @override
  Future<Iterable<Note>?> notes({required LoginHandle? handle}) {
    final acceptedHandle = LoginHandle.foo();

    return Future.delayed(
      const Duration(seconds: 2),
      (() {
        return acceptedHandle == handle ? mockedNotes : null;
      }),
    );
  }
}

abstract class AppAction {}

class LoginAction implements AppAction {
  final String email;
  final String password;

  LoginAction({
    required this.email,
    required this.password,
  });
}

class NotesAction implements AppAction {
  NotesAction();
}

class AppState {
  final LoginHandle? handle;
  final Errors? errors;
  final bool loading;
  final Iterable<Note>? fetchedNotes;

  AppState({
    required this.handle,
    required this.errors,
    required this.loading,
    required this.fetchedNotes,
  });

  AppState.empty()
      : errors = null,
        fetchedNotes = null,
        handle = null,
        loading = false;
}

class AppBloc extends Bloc<AppAction, AppState> {
  final LoginProtocol loginProtocol;
  final NotesProtocol notesProtocol;
  AppBloc({required this.loginProtocol, required this.notesProtocol})
      : super(AppState.empty()) {
    on<LoginAction>((event, emit) async {
      emit(
        AppState(
          handle: null,
          errors: null,
          fetchedNotes: null,
          loading: true,
        ),
      );
      final String email = event.email;
      final String password = event.password;
      final loginHandle =
          await loginProtocol.login(email: email, password: password);

      emit(
        AppState(
          handle: loginHandle,
          errors: loginHandle == null ? Errors.invalidHandle : null,
          loading: false,
          fetchedNotes: null,
        ),
      );
    });

    on<NotesAction>((event, emit) async {
      emit(
        AppState(
          handle: state.handle,
          errors: null,
          loading: true,
          fetchedNotes: null,
        ),
      );
      final notes = await notesProtocol.notes(handle: state.handle);

      emit(
        AppState(
          handle: state.handle,
          errors: state.handle == null ? Errors.invalidHandle : null,
          loading: false,
          fetchedNotes: notes,
        ),
      );
    });
  }
}

class LoginView extends HookWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoginView'),
      ),
      body: Column(
        children: [
          TextField(
            controller: emailController,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'enter your email here'),
          ),
          TextField(
            controller: passwordController,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'enter your password here'),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text;
              final pass = passwordController.text;

              context.read<AppBloc>().add(
                    LoginAction(email: email, password: pass),
                  );
            },
            child: const Text('submmit'),
          ),
        ],
      ),
    );
  }
}

class NotesView extends StatelessWidget {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NotesView'),
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          final notes = state.fetchedNotes;

          return Expanded(
            child: ListView.builder(
              itemCount: state.fetchedNotes?.length,
              itemBuilder: ((context, index) {
                final note = notes?.elementAt(index);
                return ListTile(
                  title: Text(note!.title),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HomePage')),
      body: BlocConsumer<AppBloc, AppState>(
        listener: (context, state) {
          if (state.loading) {
            const CircularProgressIndicator();
          } else if (state.errors == Errors.invalidHandle) {
            const Text('Error');
          }
        },
        builder: (context, state) {
          if (state.fetchedNotes == null) {
            return const LoginView();
          } else {
            return const NotesView();
          }
        },
      ),
    );
  }
}


