import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/voyage_art.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _collectionKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ProductProvider>();
        _search.text = provider.searchQuery;
        provider.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRAND LINE'),
        leading: const Icon(Icons.explore_outlined),
        actions: [
          IconButton(
            tooltip: 'My orders',
            onPressed: () => Navigator.pushNamed(context, '/orders'),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Shopping bag',
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          IconButton(
            tooltip: auth.isLoggedIn ? 'Sign out' : 'Sign in',
            onPressed: () async {
              if (auth.isLoggedIn) await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
            icon: Icon(auth.isLoggedIn ? Icons.logout : Icons.person_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: products.fetchProducts,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'THE GRAND LINE TRADING CO.  /  ONE PIECE COLLECTION',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.7,
                              height: 1.6,
                            ),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth > 650;
                            final copy = Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'FOR THE ONES WHO DREAM',
                                    style: TextStyle(
                                      color: Color(0xFFDBA45F),
                                      fontSize: 10,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'A little treasure.\nA grand adventure.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          color: AppTheme.paper,
                                          fontSize: wide ? 52 : 38,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Figures, everyday essentials, and pieces of a world\nyou never quite leave behind.',
                                    style: TextStyle(
                                      color: Color(0xFFCED5CC),
                                      height: 1.7,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.paper,
                                      side: const BorderSide(
                                        color: Color(0xFF83928A),
                                      ),
                                      padding: const EdgeInsets.all(18),
                                      shape: const RoundedRectangleBorder(),
                                    ),
                                    onPressed: () => Scrollable.ensureVisible(
                                      _collectionKey.currentContext!,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.south_east,
                                      size: 16,
                                    ),
                                    label: const Text('Explore the collection'),
                                  ),
                                ],
                              ),
                            );
                            return Container(
                              color: AppTheme.ink,
                              child: wide
                                  ? Row(
                                      children: [
                                        Expanded(flex: 3, child: copy),
                                        const Expanded(
                                          flex: 2,
                                          child: SizedBox(
                                            height: 350,
                                            child: VoyageArt(),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        copy,
                                        const SizedBox(
                                          height: 170,
                                          width: double.infinity,
                                          child: VoyageArt(),
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            children: [
                              Icon(Icons.explore_outlined, size: 17),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'From the East Blue to your everyday.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                'EST. 2026',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 24),
                        Text(
                          'The collection',
                          key: _collectionKey,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find your next keepsake.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _search,
                          onChanged: (value) {
                            setState(() {});
                            products.setSearchQuery(value);
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Search for a character, a story, a treasure…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(_search.clear);
                                      products.setSearchQuery('');
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in ProductProvider.categories)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected:
                                        products.selectedCategory == category,
                                    showCheckmark: false,
                                    selectedColor: AppTheme.ink,
                                    labelStyle: TextStyle(
                                      color:
                                          products.selectedCategory == category
                                          ? AppTheme.paper
                                          : AppTheme.ink,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    onSelected: (_) =>
                                        products.setCategory(category),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (products.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (products.error != null)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  products.error!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: products.retry,
                                  child: const Text('Try again'),
                                ),
                              ],
                            ),
                          )
                        else if (products.products.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text(
                                'No treasures found. Try a different search.',
                              ),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth < 330
                                  ? 1
                                  : constraints.maxWidth < 650
                                  ? 2
                                  : constraints.maxWidth < 960
                                  ? 3
                                  : 4;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 20,
                                      mainAxisExtent:
                                          340 +
                                          (MediaQuery.textScalerOf(context)
                                                      .scale(15) -
                                                  15) *
                                              5,
                                    ),
                                itemCount: products.products.length,
                                itemBuilder: (context, index) => ProductCard(
                                  product: products.products[index],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/product',
                                    arguments: products.products[index],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 40),
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'GRAND LINE  /  KEEP THE ADVENTURE CLOSE.',
                            style: TextStyle(fontSize: 10, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
