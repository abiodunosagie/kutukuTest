import 'package:go_router/go_router.dart';
import 'package:kutuku/Onboarding/onboarding_screen.dart';
import 'package:kutuku/views/about_screen.dart';
import 'package:kutuku/views/auth/login_screen.dart';
import 'package:kutuku/views/auth/signup.dart';
import 'package:kutuku/views/auth/verification_screen.dart';
import 'package:kutuku/views/dashboard.dart';
import 'package:kutuku/views/home_page.dart';
import 'package:kutuku/views/not_found_screen.dart';
import 'package:kutuku/views/profile_screen.dart';

class AppRouter {
  static const homeRoute = '/';
  static const aboutRoute = '/about';
  static const profileRoute = '/profile';
  static const dashboardRoute = '/dashboard';
  static const loginRoute = '/login';
  static const signupRoute = '/signup';
  static const onboardingRoute = 'onboarding';
  static const otp = '/otp';

  // ROUTES NAMES
  static const String login = 'login';
  static const String home = 'home';
  static const String about = 'about';
  static const String profile = 'profile';
  static const String dashboard = 'dashboard';
  static const String onboarding = 'onboarding';
  static const String signup = 'signup';
  static const String otp_screen = 'otp';
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: AppRouter.homeRoute,
      name: AppRouter.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRouter.loginRoute,
      name: AppRouter.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRouter.aboutRoute,
      name: AppRouter.about,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRouter.profileRoute,
      name: AppRouter.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRouter.onboardingRoute,
      name: AppRouter.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRouter.dashboardRoute,
      name: AppRouter.dashboard,
      builder: (context, state) => const Dashboard(),
    ),
    GoRoute(
      path: AppRouter.signupRoute,
      name: AppRouter.signup,
      builder: (context, state) => const Signup(),
    ),
    GoRoute(
      path: AppRouter.otp,
      name: AppRouter.otp_screen,
      builder: (context, state) => const VerificationScreen(),
    ),
  ],
);
