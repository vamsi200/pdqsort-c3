import pdqsort;
import std::collections::list;

struct Big
{
	long key;
	long a;
	long b;
	long c;
}

const usz[*] TEST_SIZES = {
	0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 23, 24, 25, 31, 32, 33,
	63, 64, 65, 100, 127, 128, 129, 200, 500, 1000, 3000, 5000
};
const int NUM_PATTERNS  = 7;
const usz MAX_N         = 5000;

int[MAX_N] t_int;
int[MAX_N] t_ref;
float[MAX_N] t_f32;
float[MAX_N] t_f32_ref;
double[MAX_N] t_f64;
double[MAX_N] t_f64_ref;

Big[MAX_N] t_big;

fn void test_sort_empty() @test
{
	int[] data = { };
	pdqsort(data);
	assert(data.len == 0);
}

fn void test_sort_single_element() @test
{
	int[] data = { 42 };
	pdqsort(data);
	assert(data[0] == 42);
}

fn void test_sort_two_elements_sorted() @test
{
	int[] data = { 1, 2 };
	pdqsort(data);
	assert(data[0] == 1);
	assert(data[1] == 2);
}

fn void test_sort_two_elements_reversed() @test
{
	int[] data = { 2, 1 };
	pdqsort(data);
	assert(data[0] == 1);
	assert(data[1] == 2);
}

fn void test_sort_already_sorted() @test
{
	int[] data = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
	pdqsort(data);

	for (usz i = 1; i < data.len; i++)
	{
		assert(data[i - 1] <= data[i]);
	}
}

fn void test_sort_reverse_sorted() @test
{
	int[] data = { 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
	pdqsort(data);

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

	pdqsort(data);

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

	pdqsort(data);

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

	pdqsort(data);

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

	pdqsort(data);

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

	pdqsort(data);

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

	pdqsort(data);

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

	pdqsort(data);

	for (usz i = 1; i < data.len; i++)
	{
		assert(data[i - 1] <= data[i]);
	}
}

fn void test_sort_preserves_element_count() @test
{
	int[] data       = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5 };
	usz original_len = data.len;

	pdqsort(data);

	assert(data.len == original_len);
}

fn void test_sort_preserves_elements() @test
{
	int[] data       = { 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5 };
	int[11] expected = { 1, 1, 2, 3, 3, 4, 5, 5, 5, 6, 9 };

	pdqsort(data);

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
	pdqsort(sorted);

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
	pdqsort(sorted);

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
			check_sort(n, pattern, false, pdqsort::log2(n + 1), &rng);
			check_sort(n, pattern, true, pdqsort::log2(n + 1), &rng);
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
			check_sort(n, pattern, false, pdqsort::log2(n), &rng);
			check_sort(n, pattern, true, pdqsort::log2(n), &rng);
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
		check_sort(n, pattern, trial % 2 == 0, pdqsort::log2(n + 1), &rng);
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

fn int gen_val(int pattern, usz i, usz n, uint* s)
{
	uint r = next_rand(s);
	switch (pattern)
	{
		case 0: return (int)r;
		case 1: return (int)i;
		case 2: return (int)(n - i);
		case 3: return 42;
		case 4: return (int)(r % 4) - 2;
		case 5: return (int)(i % 17);
		default: return (int)i - (int)((i % 13 == 0) ? 5 : 0);
	}
}

macro void ref_sort(slice)
{
	for (usz i = 1; i < slice.len; i++)
	{
		var key = slice[i];
		usz j = i;
		while (j > 0 && slice[j - 1] > key)
		{
			slice[j] = slice[j - 1];
			j--;
		}
		slice[j] = key;
	}
}

fn int cmp_int_t(int* x, int* y)
{
	return *x < *y ? -1 : (*x > *y ? 1 : 0);
}

fn int cmp_big(Big* x, Big* y)
{
	return x.key < y.key ? -1 : (x.key > y.key ? 1 : 0);
}

fn void test_branchless_int_no_cmp() @test
{
	foreach (n : TEST_SIZES)
	{
		for (int p = 0; p < NUM_PATTERNS; p++)
		{
			uint s = 0x12345678 + (uint)n;
			for (usz i = 0; i < n; i++) t_int[i] = t_ref[i] = gen_val(p, i, n, &s);
			ref_sort(t_ref[:n]);
			pdqsort_branchless(t_int[:n]);
			for (usz i = 0; i < n; i++)
			{
				assert(t_int[i] == t_ref[i], "branchless int: n=%d pattern=%d idx=%d", n, p, i);
			}
		}
	}
}

fn void test_pdqsort_int_with_cmp() @test
{
	foreach (n : TEST_SIZES)
	{
		for (int p = 0; p < NUM_PATTERNS; p++)
		{
			uint s = 0xABCDEF01 + (uint)n;
			for (usz i = 0; i < n; i++) t_int[i] = t_ref[i] = gen_val(p, i, n, &s);
			ref_sort(t_ref[:n]);
			pdqsort(t_int[:n], &cmp_int_t);
			for (usz i = 0; i < n; i++)
			{
				assert(t_int[i] == t_ref[i], "int+cmp: n=%d pattern=%d idx=%d", n, p, i);
			}
		}
	}
}

fn void test_branchless_int_with_cmp() @test
{
	foreach (n : TEST_SIZES)
	{
		for (int p = 0; p < NUM_PATTERNS; p++)
		{
			uint s = 0x0F0F0F0F + (uint)n;
			for (usz i = 0; i < n; i++) t_int[i] = t_ref[i] = gen_val(p, i, n, &s);
			ref_sort(t_ref[:n]);
			pdqsort_branchless(t_int[:n], &cmp_int_t);
			for (usz i = 0; i < n; i++)
			{
				assert(t_int[i] == t_ref[i], "branchless int+cmp: n=%d pattern=%d idx=%d", n, p, i);
			}
		}
	}
}

// 32-byte struct (comparator, no network, both entry points)
fn void check_big(usz n, int p, bool branchless)
{
	uint s = 0x13572468 + (uint)n;
	for (usz i = 0; i < n; i++)
	{
		int v = gen_val(p, i, n, &s);
		t_big[i] = { (long)v, (long)v * 3, -(long)v, (long)i };
		t_ref[i] = v;
	}
	ref_sort(t_ref[:n]);

	if (branchless)
	{
		pdqsort_branchless(t_big[:n], &cmp_big);
	}
	else
	{
		pdqsort(t_big[:n], &cmp_big);
	}

	for (usz i = 0; i < n; i++)
	{
		assert(t_big[i].key == (long)t_ref[i], "Big: key mismatch n=%d pattern=%d idx=%d", n, p, i);
		assert(t_big[i].a == t_big[i].key * 3
			&& t_big[i].b
				== -t_big[i].key, "Big: payload corrupted n=%d pattern=%d idx=%d", n, p, i);
	}
}

fn void test_big_struct_both_entry_points() @test
{
	foreach (n : TEST_SIZES)
	{
		for (int p = 0; p < NUM_PATTERNS; p++)
		{
			check_big(n, p, false);
			check_big(n, p, true);
		}
	}
}

// float / double (branchless + network paths)

fn void test_float_sort() @test
{
	foreach (n : TEST_SIZES)
	{
		for (int p = 0; p < NUM_PATTERNS; p++)
		{
			uint s = 0x2468ACE0 + (uint)n;
			for (usz i = 0; i < n; i++)
			{
				float v = (float)(gen_val(p, i, n, &s) % 100000) * 0.25f;
				t_f32[i] = t_f32_ref[i] = v;
			}
			ref_sort(t_f32_ref[:n]);
			pdqsort(t_f32[:n]);
			for (usz i = 0; i < n; i++)
			{
				assert(t_f32[i] == t_f32_ref[i], "float: n=%d pattern=%d idx=%d", n, p, i);
			}
		}
	}
}

fn void test_double_sort() @test
{
	foreach (n : TEST_SIZES)
	{
		for (int p = 0; p < NUM_PATTERNS; p++)
		{
			uint s = 0x7F7F7F7F + (uint)n;
			for (usz i = 0; i < n; i++)
			{
				double v = (double)gen_val(p, i, n, &s) * 0.5;
				t_f64[i] = t_f64_ref[i] = v;
			}
			ref_sort(t_f64_ref[:n]);
			pdqsort(t_f64[:n]);
			for (usz i = 0; i < n; i++)
			{
				assert(t_f64[i] == t_f64_ref[i], "double: n=%d pattern=%d idx=%d", n, p, i);
			}
		}
	}
}

fn void test_float_branchless_forced() @test
{
	uint s = 0x55AA55AA;
	for (usz n = 0; n < 300; n++)
	{
		for (usz i = 0; i < n; i++)
		{
			float v = (float)((int)next_rand(&s) % 1000) * 0.5f;
			t_f32[i] = t_f32_ref[i] = v;
		}
		ref_sort(t_f32_ref[:n]);
		pdqsort_branchless(t_f32[:n]);
		for (usz i = 0; i < n; i++)
		{
			assert(t_f32[i] == t_f32_ref[i], "float branchless: n=%d idx=%d", n, i);
		}
	}
}

// 0-1 principle tests for the sorting networks
fn void test_network_01_int() @test
{
	for (uint m = 0; m < 256; m++)
	{
		int[8] a;
		for (usz i = 0; i < 8; i++) a[i] = (int)((m >> i) & 1);
		pdqsort(a[..]);
		for (usz i = 1; i < 8; i++) assert(a[i - 1] <= a[i], "int sort8 failed, pattern %d", m);
	}
	for (uint m = 0; m < 16; m++)
	{
		int[4] a;
		for (usz i = 0; i < 4; i++) a[i] = (int)((m >> i) & 1);
		pdqsort(a[..]);
		for (usz i = 1; i < 4; i++) assert(a[i - 1] <= a[i], "int sort4 failed, pattern %d", m);
	}
}

fn void test_network_01_float() @test
{
	for (uint m = 0; m < 256; m++)
	{
		float[8] a;
		for (usz i = 0; i < 8; i++) a[i] = (float)((m >> i) & 1);
		pdqsort(a[..]);
		for (usz i = 1; i < 8; i++) assert(a[i - 1] <= a[i], "float sort8 failed, pattern %d", m);
	}
	for (uint m = 0; m < 16; m++)
	{
		float[4] a;
		for (usz i = 0; i < 4; i++) a[i] = (float)((m >> i) & 1);
		pdqsort(a[..]);
		for (usz i = 1; i < 4; i++) assert(a[i - 1] <= a[i], "float sort4 failed, pattern %d", m);
	}
}

fn void test_network_01_double_and_branchless() @test
{
	for (uint m = 0; m < 256; m++)
	{
		double[8] a;
		for (usz i = 0; i < 8; i++) a[i] = (double)((m >> i) & 1);
		pdqsort(a[..]);
		for (usz i = 1; i < 8; i++) assert(a[i - 1] <= a[i], "double sort8 failed, pattern %d", m);

		int[8] b;
		for (usz i = 0; i < 8; i++) b[i] = (int)((m >> i) & 1);
		pdqsort_branchless(b[..]);
		for (usz i = 1; i < 8; i++) assert(b[i
			- 1] <= b[i], "branchless sort8 failed, pattern %d", m);
	}
}
