
# pdqsort-c3

An implementation of [pattern-defeating quicksort (pdqsort)](https://github.com/orlp/pdqsort) in [C3](https://c3-lang.org/).

Pdqsort is an unstable, in-place sorting algorithm that combines quicksort, insertion sort, and heapsort with pattern detection to achieve O(n log n) worst-case complexity while performing efficiently on common input distributions.

This implementation provides both standard and branchless partitioning, generic sorting with optional custom comparators, and automatic branchless selection for primitive numeric types.

Pdqsort is **not stable**. Elements comparing equal are not guaranteed to retain their original relative order.

## Usage

Import the `pdqsort` module:

```c3
import pdqsort;
```

### Basic sorting

```c3
import pdqsort;
import std::io;

fn int main(String[] args) => @pool()
{
    int[] values = { 9, 3, 7, 1, 5, 2 };

    pdqsort::pdqsort(values);

    io::printn(values);
    // { 1, 2, 3, 5, 7, 9 }

    return 0;
}
```

For integer and floating-point types, the default macro automatically selects branchless partitioning when no custom comparator is provided.

### Explicit branchless sorting

To force branchless partitioning:

```c3
pdqsort::pdqsort_branchless(values);
```

The branchless variant is primarily useful for inexpensive comparisons where branch mispredictions contribute significantly to execution time. It is not necessarily faster for every workload.

### Custom comparators

Both variants accept an optional comparison function:

```c3
fn int descending(int a, int b)
{
    return b <=> a;
}

fn void example()
{
    int[] values = { 4, 1, 9, 2, 7 };

    pdqsort::pdqsort(values, &descending);
    // { 9, 7, 4, 2, 1 }
}
```

Comparison functions must return a signed integer:

- Negative if the first element precedes the second.
- Zero if the elements compare equal.
- Positive if the first element follows the second.

Comparators may accept elements by value or by pointer. An optional context argument is also supported.

### Arrays and slices

Slices can be sorted directly. Fixed-size arrays and other supported indexable containers must be passed by reference.

```c3
int[] slice = { 5, 2, 8, 1 };
pdqsort::pdqsort(slice);

int[4] array = { 5, 2, 8, 1 };
pdqsort::pdqsort(&array);
```

Sorting modifies the supplied collection in place.

## Benchmarks

Benchmarks were compiled with **O3 optimization** and executed using C3's built-in benchmarking functionality.

Each benchmark ran for 10,000 iterations.

| Input distribution | pdqsort | Branchless |
|--------------------|--------:|-----------:|
| Random | 133.13 µs | 136.55 µs |
| Sorted | 4.57 µs | 4.59 µs |
| Reverse sorted | 11.22 µs | 11.32 µs |
| All equal | 5.63 µs | 5.66 µs |
| Many duplicates | 24.75 µs | 24.78 µs |
| Nearly sorted | 12.48 µs | 12.71 µs |

All results represent mean execution time. Lower is better.


## References and attribution

Pattern-defeating quicksort was developed by **Orson Peters**.

This project is a C3 implementation of the algorithm.

- [Original pdqsort implementation — Orson Peters](https://github.com/orlp/pdqsort)
- [Pattern-defeating Quicksort — Orson Peters](https://arxiv.org/abs/2106.05123)
- [BlockQuicksort: How Branch Mispredictions Don't Affect Quicksort](https://arxiv.org/abs/1604.06697)

Credit for the original algorithm and its underlying techniques belongs to their respective authors.

## License

See [LICENSE](LICENSE).
