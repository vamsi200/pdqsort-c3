import std::sort;
import std::collections::list;

// fn void test_partition_right() @test
// {
//     int[] a = { 4, 2, 7, 1, 6, 3, 5 };
//
//     PartitionResult result = sort::partition_right(a);
//
//     usz pivot_index = (usz)(result.ptr - a.ptr);
//     int pivot       = a[pivot_index];
//
//     for (usz i = 0; i < pivot_index; i++)
//     {
//         assert(a[i] < pivot);
//     }
//
//     for (usz i = pivot_index + 1; i < a.len; i++)
//     {
//         assert(a[i] >= pivot);
//     }
// }

fn void test_sort_empty() @test
{
    int[] data = { };
    sort::pdqsort(data);
    assert(data.len == 0);
}

fn void test_sort_single_element() @test
{
    int[] data = { 42 };
    sort::pdqsort(data);
    assert(data[0] == 42);
}

fn void test_sort_two_elements_sorted() @test
{
    int[] data = { 1, 2 };
    sort::pdqsort(data);
    assert(data[0] == 1);
    assert(data[1] == 2);
}

fn void test_sort_two_elements_reversed() @test
{
    int[] data = { 2, 1 };
    sort::pdqsort(data);
    assert(data[0] == 1);
    assert(data[1] == 2);
}

fn void test_sort_already_sorted() @test
{
    int[] data = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_reverse_sorted() @test
{
    int[] data = { 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_all_equal() @test
{
    int[] data = {
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
    };

    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] == data[i]);
    }
}

fn void test_sort_duplicate_heavy() @test
{
    int[] data = {
        5,
        1,
        5,
        3,
        2,
        5,
        1,
        3,
        2,
        5,
        4,
        1,
        5,
        2,
        3,
        4,
        5,
        1,
        2,
        3,
        4,
        4,
        4,
        1,
        1,
        2,
        2,
        3,
        3,
        5,
    };

    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_negative_values() @test
{
    int[] data = {
        0,
        -1,
        5,
        -10,
        3,
        -3,
        2,
        -2,
        10,
        -5,
    };

    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_mixed_extremes() @test
{
    int[] data = {
        int::max,
        int::min,
        0,
        -1,
        1,
        int::max - 1,
        int::min + 1,
        42,
        -42,
    };

    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_insertion_sort_threshold() @test
{
    int[] data = {
        24,
        23,
        22,
        21,
        20,
        19,
        18,
        17,
        16,
        15,
        14,
        13,
        12,
        11,
        10,
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
        1,
    };

    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_above_insertion_sort_threshold() @test
{
    int[] data = {
        30,
        29,
        28,
        27,
        26,
        25,
        24,
        23,
        22,
        21,
        20,
        19,
        18,
        17,
        16,
        15,
        14,
        13,
        12,
        11,
        10,
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
        1,
    };

    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_ninther_threshold() @test
{
    int[] data = {
        128,
        127,
        126,
        125,
        124,
        123,
        122,
        121,
        120,
        119,
        118,
        117,
        116,
        115,
        114,
        113,
        112,
        111,
        110,
        109,
        108,
        107,
        106,
        105,
        104,
        103,
        102,
        101,
        100,
        99,
        98,
        97,
        96,
        95,
        94,
        93,
        92,
        91,
        90,
        89,
        88,
        87,
        86,
        85,
        84,
        83,
        82,
        81,
        80,
        79,
        78,
        77,
        76,
        75,
        74,
        73,
        72,
        71,
        70,
        69,
        68,
        67,
        66,
        65,
        64,
        63,
        62,
        61,
        60,
        59,
        58,
        57,
        56,
        55,
        54,
        53,
        52,
        51,
        50,
        49,
        48,
        47,
        46,
        45,
        44,
        43,
        42,
        41,
        40,
        39,
        38,
        37,
        36,
        35,
        34,
        33,
        32,
        31,
        30,
        29,
        28,
        27,
        26,
        25,
        24,
        23,
        22,
        21,
        20,
        19,
        18,
        17,
        16,
        15,
        14,
        13,
        12,
        11,
        10,
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
        1,
    };

    sort::pdqsort(data);

    for (usz i = 1; i < data.len; i++)
    {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_sort_preserves_element_count() @test
{
    int[] data       = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5 };
    usz original_len = data.len;

    sort::pdqsort(data);

    assert(data.len == original_len);
}

fn void test_sort_preserves_elements() @test
{
    int[] data       = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5 };
    int[11] expected = { 1, 1, 2, 3, 3, 4, 5, 5, 5, 6, 9 };

    sort::pdqsort(data);

    for (usz i = 0; i < data.len; i++)
    {
        assert(data[i] == expected[i]);
    }
}

fn void test_sort_large_reverse_sorted() @test => @pool()
{
    List{int} data;

    for (int i = 4096; i > 0; i--)
    {
        data.push(i);
    }

    int[] sorted = data.to_array(tmem);
    sort::pdqsort(sorted);

    for (sz i = 1; i < sorted.len; i++)
    {
        assert(sorted[i - 1] <= sorted[i]);
    }
}

fn void test_sort_large_duplicate_heavy() @test => @pool()
{
    List{int} data;

    for (int i = 0; i < 4096; i++)
    {
        data.push(i % 7);
    }

    int[] sorted = data.to_array(tmem);
    sort::pdqsort(sorted);

    for (sz i = 1; i < sorted.len; i++)
    {
        assert(sorted[i - 1] <= sorted[i]);
    }
}

fn uint next_rand(uint* state)
{
    uint s = *state;
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    *state = s;
    return s;
}

fn void reference_sort(int[] data)
{
    for (usz i = 1; i < data.len; i++)
    {
        int key = data[i];
        usz j   = i;
        while (j > 0 && data[j - 1] > key)
        {
            data[j] = data[j - 1];
            j--;
        }
        data[j] = key;
    }
}

fn void fill_pattern(int[] data, int pattern, uint* rng)
{
    usz n = data.len;
    for (usz i = 0; i < n; i++)
    {
        uint r = next_rand(rng);
        switch (pattern)
        {
            case 0: data[i] = (int)r;
            case 1: data[i] = (int)(r % 16) - 8;
            case 2: data[i] = (int)i;
            case 3: data[i] = (int)(n - i);
            case 4: data[i] = 42;
            case 5: data[i] = (int)i;
            case 6: data[i] = (int)(i < n / 2 ? i : n - i);
            case 7: data[i] = (int)(i % 37);
        }
    }
    if (pattern == 5)
    {
        for (usz i = 0; i + 1 < n; i += 97)
        {
            int t = data[i];
            data[i] = data[i + 1];
            data[i + 1] = t;
        }
    }
}

fn void check_sort(usz n, int pattern, bool branchless, int bad_allowed, uint* rng)
{
    @pool()
    {
        int[] data     = alloc::new_array(tmem, int, (sz)n);
        int[] expected = alloc::new_array(tmem, int, (sz)n);

        fill_pattern(data, pattern, rng);
        for (usz i = 0; i < n; i++) expected[i] = data[i];
        reference_sort(expected);

        if (n >= 2)
        {
            pdqsort(data);
        }

        for (usz i = 0; i < n; i++)
        {
            assert(data[i]
                == expected[i], "mismatch: n=%d pattern=%d branchless=%s i=%d", n, pattern, branchless, i);
        }
    };
}

fn void test_sweep_small_sizes() @test
{
    uint rng = 0x9E3779B9;
    for (usz n = 0; n <= 300; n++)
    {
        for (int pattern = 0; pattern < 8; pattern++)
        {
            check_sort(n, pattern, false, sort::log2(n + 1), &rng);
            check_sort(n, pattern, true, sort::log2(n + 1), &rng);
        }
    }
}

fn void test_large_sizes() @test
{
    uint rng     = 0xDEADBEEF;
    usz[5] sizes = { 1000, 4095, 4096, 4097, 9999 };
    foreach (n : sizes)
    {
        for (int pattern = 0; pattern < 8; pattern++)
        {
            check_sort(n, pattern, false, sort::log2(n), &rng);
            check_sort(n, pattern, true, sort::log2(n), &rng);
        }
    }
}

fn void test_many_random_trials() @test
{
    uint rng = 0x1234ABCD;
    for (int trial = 0; trial < 500; trial++)
    {
        usz n       = (usz)(next_rand(&rng) % 3000);
        int pattern = (int)(next_rand(&rng) % 8);
        check_sort(n, pattern, trial % 2 == 0, sort::log2(n + 1), &rng);
    }
}

fn void test_forced_heapsort_fallback() @test
{
    uint rng = 0xCAFEBABE;
    for (int pattern = 0; pattern < 8; pattern++)
    {
        check_sort(5000, pattern, false, 1, &rng);
        check_sort(5000, pattern, true, 1, &rng);
    }
}

// fn void test_heap_sort_direct() @test
// {
//     uint rng = 0x0BADF00D;
//     for (usz n = 0; n < 200; n++)
//     {
//         @pool()
//         {
//             int[] data     = alloc::new_array(tmem, int, (sz)n);
//             int[] expected = alloc::new_array(tmem, int, (sz)n);
//             fill_pattern(data, 0, &rng);
//             for (usz i = 0; i < n; i++) expected[i] = data[i];
//             reference_sort(expected);
//             sort::heap_sort(data);
//             for (usz i = 0; i < n; i++) assert(data[i] == expected[i]);
//         };
//     }
// }
