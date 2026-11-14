import std::sort;
import std::collections::list;
import std::math::random;
import std::io;
import std::time;

macro int[] make_array(Allocator allocator, int n)
{
    List{int} k;
    while (k.len() < n)
    {
        int val = random::rand(n);
        k.push(val);
    }
    return k.to_array(allocator);
}

fn int main(String[] args) => @pool()
{
    int[] original = make_array(tmem, 9);

    io::printfn("Before:");
    io::printn(original);

    pdqsort(original);

    io::printfn("After:");
    io::printn(original);

    return 0;
}

const BENCH_SIZE = 9999;

int[BENCH_SIZE] bench_random;
int[BENCH_SIZE] bench_sorted;
int[BENCH_SIZE] bench_reverse;
int[BENCH_SIZE] bench_equal;
int[BENCH_SIZE] bench_duplicates;
int[BENCH_SIZE] bench_nearly_sorted;
int[BENCH_SIZE] bench_work;

uint bench_sink;
bool bench_ready;

macro void swap_int(int* a, int* b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

fn void fill_bench_data(int[] data, int pattern)
{
    uint state = 0x12345678;

    for (sz i = 0; i < data.len; i++)
    {
        state ^= state << 13;
        state ^= state >> 17;
        state ^= state << 5;

        switch (pattern)
        {
            case 0: data[i] = (int)(state & 0x7FFFFFFF);
            case 1: data[i] = (int)i;
            case 2: data[i] = (int)(data.len - i);
            case 3: data[i] = 42;
            case 4: data[i] = (int)(state % 16) - 8;
            case 5: data[i] = (int)i;
        }
    }

    if (pattern == 5)
    {
        for (sz i = 0; i + 1 < data.len; i += 97)
        {
            swap_int(&data[i], &data[i + 1]);
        }
    }
}

fn void init_bench_data()
{
    fill_bench_data(bench_random[..], 0);
    fill_bench_data(bench_sorted[..], 1);
    fill_bench_data(bench_reverse[..], 2);
    fill_bench_data(bench_equal[..], 3);
    fill_bench_data(bench_duplicates[..], 4);
    fill_bench_data(bench_nearly_sorted[..], 5);
}

fn void ensure_init()
{
    if (!bench_ready)
    {
        init_bench_data();
        bench_ready = true;
    }
}

fn int[] get_bench_data(int pattern)
{
    switch (pattern)
    {
        case 0: return bench_random[..];
        case 1: return bench_sorted[..];
        case 2: return bench_reverse[..];
        case 3: return bench_equal[..];
        case 4: return bench_duplicates[..];
        case 5: return bench_nearly_sorted[..];
        default: return bench_random[..];
    }
}

fn uint checksum(int[] data)
{
    uint hash = 0;
    for (sz i = 0; i < data.len; i++)
    {
        hash = hash * 31 + (uint)data[i];
    }
    return hash;
}

fn void run_sort_benchmark(int pattern, int algorithm, sz n)
{
    ensure_init();

    int[] original = get_bench_data(pattern);
    int[] data     = bench_work[:n];
    data[..] = original[:n];

    switch (algorithm)
    {
        case 0:
            sort::pdqsort(data);
        case 1:
            sort::pdqsort(data);
        default:
            break;
    }

    bench_sink = checksum(data);
}

fn bool is_sorted(int[] data)
{
    for (sz i = 1; i < data.len; i++)
    {
        if (data[i - 1] > data[i]) return false;
    }
    return true;
}

fn void bench_pdq_random() @benchmark => run_sort_benchmark(0, 0, BENCH_SIZE);
fn void bench_pdq_branchless_random() @benchmark => run_sort_benchmark(0, 1, BENCH_SIZE);
fn void bench_pdq_sorted() @benchmark => run_sort_benchmark(1, 0, BENCH_SIZE);
fn void bench_pdq_branchless_sorted() @benchmark => run_sort_benchmark(1, 1, BENCH_SIZE);
fn void bench_pdq_reverse() @benchmark => run_sort_benchmark(2, 0, BENCH_SIZE);
fn void bench_pdq_branchless_reverse() @benchmark => run_sort_benchmark(2, 1, BENCH_SIZE);
fn void bench_pdq_equal() @benchmark => run_sort_benchmark(3, 0, BENCH_SIZE);
fn void bench_pdq_branchless_equal() @benchmark => run_sort_benchmark(3, 1, BENCH_SIZE);
fn void bench_pdq_duplicates() @benchmark => run_sort_benchmark(4, 0, BENCH_SIZE);
fn void bench_pdq_branchless_duplicates() @benchmark => run_sort_benchmark(4, 1, BENCH_SIZE);
fn void bench_pdq_nearly_sorted() @benchmark => run_sort_benchmark(5, 0, BENCH_SIZE);
fn void bench_pdq_branchless_nearly_sorted() @benchmark => run_sort_benchmark(5, 1, BENCH_SIZE);
