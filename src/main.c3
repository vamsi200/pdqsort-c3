module pdqsort;

import std::io;
import std::collections::list;
import std::math::random;
import std::time;

const int INSERTION_SORT_THRESHOLD     = 24;
const int NINTER_THRESHOLD             = 128;
const int PARTIAL_INSERTION_SORT_LIMIT = 8;
const int BLOCK_SIZE                   = 64;
const int CACHELINE_SIZE               = 64;

struct PartitionResult {
    int* ptr;
    bool flag;
}

fn int log2(usz n) @inline {
    int log = 0;
    while ((n >>= 1)) log++;
    return log;
}

macro void swap_int(int* a, int* b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

macro void sort2(int* a, int* b) {
    if (*b < *a) {
        swap_int(a, b);
    }
}

macro void sort3(int* a, int* b, int* c) {
    sort2(a, b);
    sort2(b, c);
    sort2(a, b);
}

macro int[] make_array(Allocator allocator, int n) {
    List{int} k;
    while (k.len() < n) {
        int val = random::rand(n);
        k.push(val);
    }
    return k.to_array(allocator);
}

fn void* align_cacheline(void* p) {
    uptr addr = (uptr)p;
    addr = (addr + CACHELINE_SIZE - 1) & ~(CACHELINE_SIZE - 1);
    return (void*)addr;
}

fn void swap_offsets(
    int* first,
    int* last,
    char* offset_l,
    char* offset_r,
    usz num,
    bool use_swaps
) {
    if (use_swaps) {
        for (usz i = 0; i < num; i++) {
            int* l = first + (usz)offset_l[i];
            int* r = last - (usz)offset_r[i];

            int tmp = *l;
            *l = *r;
            *r = tmp;
        }
    } else if (num > 0) {
        int* l = first + (usz)offset_l[0];
        int* r = last - (usz)offset_r[0];

        int tmp = *l;
        *l = *r;

        for (usz i = 1; i < num; i++) {
            l = first + (usz)offset_l[i];
            *r = *l;

            r = last - (usz)offset_r[i];
            *l = *r;
        }

        *r = tmp;
    }
}

// Insertion sort
fn void insertion_sort(int[] data) @inline {
    int* begin = data.ptr;
    int* end   = begin + data.len;

    for (int* current = begin + 1; current < end; current++) {
        int key   = *current;
        int* hole = current;

        while (hole > begin && *(hole - 1) > key) {
            *hole = *(hole - 1);
            hole--;
        }

        *hole = key;
    }
}

// Requires a valid sentinel at begin[-1].
fn void unguarded_insertion_sort(int[] data) @inline {
    int* begin = data.ptr;
    int* end   = begin + data.len;

    for (int* current = begin + 1; current < end; current++) {
        int key   = *current;
        int* hole = current;

        while (*(hole - 1) > key) {
            *hole = *(hole - 1);
            hole--;
        }

        *hole = key;
    }
}

fn bool partial_insertion_sort(int[] data) @inline {
    int* begin = data.ptr;
    int* end   = begin + data.len;

    usz moves = 0;

    for (int* current = begin + 1; current < end; current++) {
        int key   = *current;
        int* hole = current;

        while (hole > begin && *(hole - 1) > key) {
            *hole = *(hole - 1);
            hole--;
            moves++;

            if (moves > PARTIAL_INSERTION_SORT_LIMIT) {
                *hole = key;
                return false;
            }
        }

        *hole = key;
    }

    return true;
}

// Heapsort fallback
fn void sift_down(int[] data, usz root, usz end) @inline {
    while (root < end / 2) {
        usz child = root * 2 + 1;

        if (child + 1 < end && data[child] < data[child + 1]) {
            child++;
        }

        if (data[root] >= data[child]) {
            return;
        }

        int tmp = data[root];
        data[root] = data[child];
        data[child] = tmp;

        root = child;
    }
}

fn void heap_sort(int[] data) {
    usz n = data.len;

    if (n < 2) {
        return;
    }

    usz start = n / 2;

    while (start > 0) {
        start--;
        sift_down(data, start, n);
    }

    usz end = n;

    while (end > 1) {
        end--;

        int tmp = data[0];
        data[0] = data[end];
        data[end] = tmp;

        sift_down(data, 0, end);
    }
}

// Pattern breaking
fn void break_patterns(int[] data) @inline {
    usz n = data.len;

    if (n < 8) {
        return;
    }

    usz mid = n / 2;

    swap_int(&data[0], &data[n / 4]);
    swap_int(&data[mid], &data[(n * 3) / 4]);
    swap_int(&data[n - 1], &data[mid]);
}

fn PartitionResult partition_right_branchless(int[] value) {
    int* begin = value.ptr;
    int* end   = begin + value.len;

    int pivot  = *begin;
    int* first = begin + 1;
    int* last  = end;

    while (first < last && *first < pivot) {
        first++;
    }

    while (first < last && *(last - 1) >= pivot) {
        last--;
    }

    bool already_partitioned = first >= last;

    if (!already_partitioned) {
        swap_int(first, last - 1);

        first++;
        last--;

        char[BLOCK_SIZE + CACHELINE_SIZE] offsets_l_storage;
        char[BLOCK_SIZE + CACHELINE_SIZE] offsets_r_storage;

        char* offsets_l = (char*)align_cacheline(&offsets_l_storage);
        char* offsets_r = (char*)align_cacheline(&offsets_r_storage);

        int* offset_l_base = first;
        int* offset_r_base = last;

        usz num_l   = 0;
        usz num_r   = 0;
        usz start_l = 0;
        usz start_r = 0;

        while (first < last) {
            usz num_unknown = (usz)(last - first);

            usz left_split = num_l == 0
                ? (num_r == 0 ? num_unknown / 2 : num_unknown)
                : 0;

            usz right_split = num_r == 0
                ? num_unknown - left_split
                : 0;

            if (left_split >= BLOCK_SIZE) {
                for (char i = 0; i < BLOCK_SIZE;) {
                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;

                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;

                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;

                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;

                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;

                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;

                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;

                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = i;
                    }
                    i++;
                    first++;
                }
            } else {
                for (usz i = 0; i < left_split; i++) {
                    if (!(*first < pivot)) {
                        offsets_l[num_l++] = (char)i;
                    }
                    first++;
                }
            }

            if (right_split >= BLOCK_SIZE) {
                for (char i = 0; i < BLOCK_SIZE;) {
                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }

                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }

                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }

                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }

                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }

                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }

                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }

                    i++;
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = i;
                    }
                }
            } else {
                for (usz i = 0; i < right_split; i++) {
                    last--;
                    if (*last < pivot) {
                        offsets_r[num_r++] = (char)(i + 1);
                    }
                }
            }

            usz num = num_l < num_r ? num_l : num_r;

            swap_offsets(
                offset_l_base,
                offset_r_base,
                offsets_l + start_l,
                offsets_r + start_r,
                num,
                num_l == num_r
            );

            num_l -= num;
            num_r -= num;

            start_l += num;
            start_r += num;

            if (num_l == 0) {
                start_l = 0;
                offset_l_base = first;
            }

            if (num_r == 0) {
                start_r = 0;
                offset_r_base = last;
            }
        }

        if (num_l > 0) {
            offsets_l += (long)start_l;

            while (num_l > 0) {
                last--;

                int* l = offset_l_base + (usz)offsets_l[num_l - 1];
                int ltmp = *l;

                *l = *last;
                *last = ltmp;

                num_l--;
            }

            first = last;
        }

        if (num_r > 0) {
            offsets_r += (long)start_r;

            while (num_r > 0) {
                int* r = offset_r_base - (usz)offsets_r[num_r - 1];

                int rtmp = *r;
                *r = *first;
                *first = rtmp;

                first++;
                num_r--;
            }

            last = first;
        }
    }

    int* pivot_pos = first - 1;

    *begin = *pivot_pos;
    *pivot_pos = pivot;

    PartitionResult pr;
    pr.ptr = pivot_pos;
    pr.flag = already_partitioned;

    return pr;
}

fn PartitionResult partition_right(int[] value) @inline {
    int* begin = value.ptr;
    int* end   = begin + value.len;

    int pivot  = *begin;
    int* first = begin + 1;
    int* last  = end;

    bool already_partitioned = true;

    while (first < last) {
        while (first < last && *first < pivot) {
            first++;
        }

        while (first < last && *(last - 1) >= pivot) {
            last--;
        }

        if (first < last) {
            swap_int(first, last - 1);

            first++;
            last--;

            already_partitioned = false;
        }
    }

    int* pivot_pos = first - 1;

    *begin = *pivot_pos;
    *pivot_pos = pivot;

    PartitionResult pr;
    pr.ptr = pivot_pos;
    pr.flag = already_partitioned;

    return pr;
}

fn int* partition_left(int[] value) @inline {
    int* begin = value.ptr;
    int* end   = begin + value.len;

    int pivot  = *begin;
    int* first = begin + 1;
    int* last  = end;

    while (first < last) {
        while (first < last && *first <= pivot) {
            first++;
        }

        while (first < last && *(last - 1) > pivot) {
            last--;
        }

        if (first < last) {
            swap_int(first, last - 1);

            first++;
            last--;
        }
    }

    int* pivot_pos = first - 1;

    *begin = *pivot_pos;
    *pivot_pos = pivot;

    return pivot_pos;
}

fn void pdqsort_loop(
    int[] value,
    int bad_allowed,
    bool leftmost,
    bool branchless,
    int previous
) @inline {
    while (true) {
        usz size = value.len;

        if (size < INSERTION_SORT_THRESHOLD) {
            if (leftmost) {
                insertion_sort(value);
            } else {
                unguarded_insertion_sort(value);
            }

            return;
        }

        usz s2 = size / 2;

        if (size > NINTER_THRESHOLD) {
            sort3(&value[0], &value[s2], &value[size - 1]);
            sort3(&value[1], &value[s2 - 1], &value[size - 2]);
            sort3(&value[2], &value[s2 + 1], &value[size - 3]);
            sort3(&value[s2 - 1], &value[s2], &value[s2 + 1]);

            swap_int(&value[0], &value[s2]);
        } else {
            sort3(&value[s2], &value[0], &value[size - 1]);
        }

        // Equal elements from the previous partition.
        //
        // C++:
        // !leftmost && !comp(*(begin - 1), *begin)
        //
        // With < as comp this means:
        // previous >= pivot

        if (!leftmost && previous >= value[0]) {
            int* pivot_pos = partition_left(value);

            usz pivot_index = (usz)(pivot_pos - value.ptr);

            previous = *pivot_pos;

            value = value[pivot_index + 1 : size - pivot_index - 1];

            continue;
        }

        PartitionResult part_result;

        if (branchless) {
            part_result = partition_right_branchless(value);
        } else {
            part_result = partition_right(value);
        }

        int* pivot_pos           = part_result.ptr;
        bool already_partitioned = part_result.flag;

        usz pivot_index = (usz)(pivot_pos - value.ptr);

        usz l_size = pivot_index;
        usz r_size = size - pivot_index - 1;

        bool highly_unbalanced = l_size < size / 8 || r_size < size / 8;

        if (highly_unbalanced) {
            // Too many bad partitions -> heapsort.
            bad_allowed--;

            if (bad_allowed <= 0) {
                heap_sort(value);
                return;
            }

            // Shuffle left partition.
            if (l_size >= INSERTION_SORT_THRESHOLD) {
                swap_int(&value[0], &value[l_size / 4]);

                swap_int(
                    &value[pivot_index - 1],
                    &value[pivot_index - l_size / 4]
                );

                if (l_size > NINTER_THRESHOLD) {
                    swap_int(&value[1], &value[l_size / 4 + 1]);
                    swap_int(&value[2], &value[l_size / 4 + 2]);

                    swap_int(
                        &value[pivot_index - 2],
                        &value[pivot_index - l_size / 4 - 1]
                    );

                    swap_int(
                        &value[pivot_index - 3],
                        &value[pivot_index - l_size / 4 - 2]
                    );
                }
            }

            // Shuffle right partition.
            if (r_size >= INSERTION_SORT_THRESHOLD) {
                swap_int(
                    &value[pivot_index + 1],
                    &value[pivot_index + 1 + r_size / 4]
                );

                swap_int(
                    &value[size - 1],
                    &value[size - r_size / 4]
                );

                if (r_size > NINTER_THRESHOLD) {
                    swap_int(
                        &value[pivot_index + 2],
                        &value[pivot_index + 2 + r_size / 4]
                    );

                    swap_int(
                        &value[pivot_index + 3],
                        &value[pivot_index + 3 + r_size / 4]
                    );

                    swap_int(
                        &value[size - 2],
                        &value[size - 2 - r_size / 4]
                    );

                    swap_int(
                        &value[size - 3],
                        &value[size - 3 - r_size / 4]
                    );
                }
            }
        } else {
            // Balanced + already partitioned.
            if (already_partitioned) {
                bool left_sorted = partial_insertion_sort(value[0 : l_size]);
                bool right_sorted = partial_insertion_sort(
                    value[pivot_index + 1 : r_size]
                );

                if (left_sorted && right_sorted) {
                    return;
                }
            }
        }

        // Sort left partition recursively.
        pdqsort_loop(
            value[0 : pivot_index],
            bad_allowed,
            leftmost,
            branchless,
            previous
        );

        // Tail recursion elimination.
        previous = *pivot_pos;
        value = value[pivot_index + 1 : r_size];
        leftmost = false;
    }
}

fn void pdqsort(int[] value) {
    if (value.len < 2) {
        return;
    }

    int bad_allowed = log2(value.len);

    pdqsort_loop(value, bad_allowed, true, true, 0);
}

fn int main(String[] args) => @pool(){
    int[] original = make_array(tmem, 9);

    io::printfn("Before:");
    io::printn(original);

    pdqsort(original);

    io::printfn("After:");
    io::printn(original);

    return 0;
}

// tests
fn void test_partition_right() @test {
    int[] a = { 4, 2, 7, 1, 6, 3, 5 };

    PartitionResult result = partition_right(a);

    usz pivot_index = (usz)(result.ptr - a.ptr);
    int pivot = a[pivot_index];

    for (usz i = 0; i < pivot_index; i++) {
        assert(a[i] < pivot);
    }

    for (usz i = pivot_index + 1; i < a.len; i++) {
        assert(a[i] >= pivot);
    }
}

fn void test_pdqsort_empty() @test {
    int[] data = {};
    pdqsort(data);
    assert(data.len == 0);
}

fn void test_pdqsort_single_element() @test {
    int[] data = { 42 };
    pdqsort(data);
    assert(data[0] == 42);
}

fn void test_pdqsort_two_elements_sorted() @test {
    int[] data = { 1, 2 };
    pdqsort(data);
    assert(data[0] == 1);
    assert(data[1] == 2);
}

fn void test_pdqsort_two_elements_reversed() @test {
    int[] data = { 2, 1 };
    pdqsort(data);
    assert(data[0] == 1);
    assert(data[1] == 2);
}

fn void test_pdqsort_already_sorted() @test {
    int[] data = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_reverse_sorted() @test {
    int[] data = { 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_all_equal() @test {
    int[] data = {
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    };

    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] == data[i]);
    }
}

fn void test_pdqsort_duplicate_heavy() @test {
    int[] data = {
        5, 1, 5, 3, 2, 5, 1, 3, 2, 5,
        4, 1, 5, 2, 3, 4, 5, 1, 2, 3,
        4, 4, 4, 1, 1, 2, 2, 3, 3, 5,
    };

    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_negative_values() @test {
    int[] data = {
        0, -1, 5, -10, 3, -3, 2, -2, 10, -5,
    };

    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_mixed_extremes() @test {
    int[] data = {
        int::max, int::min, 0, -1, 1,
        int::max - 1, int::min + 1, 42, -42,
    };

    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_insertion_sort_threshold() @test {
    int[] data = {
        24, 23, 22, 21, 20, 19, 18, 17, 16, 15,
        14, 13, 12, 11, 10, 9, 8, 7, 6, 5,
        4, 3, 2, 1,
    };

    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_above_insertion_sort_threshold() @test {
    int[] data = {
        30, 29, 28, 27, 26, 25, 24, 23, 22, 21,
        20, 19, 18, 17, 16, 15, 14, 13, 12, 11,
        10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
    };

    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_ninther_threshold() @test {
    int[] data = {
        128, 127, 126, 125, 124, 123, 122, 121,
        120, 119, 118, 117, 116, 115, 114, 113,
        112, 111, 110, 109, 108, 107, 106, 105,
        104, 103, 102, 101, 100, 99, 98, 97,
        96, 95, 94, 93, 92, 91, 90, 89,
        88, 87, 86, 85, 84, 83, 82, 81,
        80, 79, 78, 77, 76, 75, 74, 73,
        72, 71, 70, 69, 68, 67, 66, 65,
        64, 63, 62, 61, 60, 59, 58, 57,
        56, 55, 54, 53, 52, 51, 50, 49,
        48, 47, 46, 45, 44, 43, 42, 41,
        40, 39, 38, 37, 36, 35, 34, 33,
        32, 31, 30, 29, 28, 27, 26, 25,
        24, 23, 22, 21, 20, 19, 18, 17,
        16, 15, 14, 13, 12, 11, 10, 9,
        8, 7, 6, 5, 4, 3, 2, 1,
    };

    pdqsort(data);

    for (usz i = 1; i < data.len; i++) {
        assert(data[i - 1] <= data[i]);
    }
}

fn void test_pdqsort_preserves_element_count() @test {
    int[] data = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5 };
    usz original_len = data.len;

    pdqsort(data);

    assert(data.len == original_len);
}

fn void test_pdqsort_preserves_elements() @test {
    int[] data = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5 };
    int[11] expected = { 1, 1, 2, 3, 3, 4, 5, 5, 5, 6, 9 };

    pdqsort(data);

    for (usz i = 0; i < data.len; i++) {
        assert(data[i] == expected[i]);
    }
}

fn void test_pdqsort_large_reverse_sorted() @test => @pool() {
    List{int} data;

    for (int i = 4096; i > 0; i--) {
        data.push(i);
    }

    int[] sorted = data.to_array(tmem);
    pdqsort(sorted);

    for (sz i = 1; i < sorted.len; i++) {
        assert(sorted[i - 1] <= sorted[i]);
    }
}

fn void test_pdqsort_large_duplicate_heavy() @test => @pool() {
    List{int} data;

    for (int i = 0; i < 4096; i++) {
        data.push(i % 7);
    }

    int[] sorted = data.to_array(tmem);
    pdqsort(sorted);

    for (sz i = 1; i < sorted.len; i++) {
        assert(sorted[i - 1] <= sorted[i]);
    }
}
