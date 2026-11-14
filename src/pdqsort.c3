module std::sort;

fn int log2(usz n) @inline
{
    return (int)(usz::size * 8 - 1) - (int)n.clz();
}

<*
 Sort list using pattern-defeating quicksort (pdqsort).
 Uses the branchless partition by default for integer types without a comparator.

 @require @list_is_by_ref(list) : "Expected a list passed by reference or be a slice"
 @require @is_sortable(list) : "The list must be indexable and support .len or .len()"
 @require @is_valid_cmp_fn(#cmp: ...cmp, #list: list, #context: ...context) : "Expected a comparison function which compares values"
 @require @is_valid_context(...cmp, ...context) : "Expected a valid context"
*>
macro void pdqsort(list, cmp = ..., context = ...) @builtin
{
    var used_cmp = $defined(cmp) ??? cmp : (TypeNotSet)null;
    var used_ctx = $defined(context) ??? context : (TypeNotSet)null;
    $if @kindof(list) == SLICE:
        var $branchless = $Typeof(used_cmp) == TypeNotSet
            &&& ($Typeof(list[0])::kind == SIGNED_INT ||| $Typeof(list[0])::kind == UNSIGNED_INT);
        pdqsort_with{$Typeof(list), $Typeof(used_cmp), $Typeof(used_ctx)}(
            list,
            $branchless,
            log2(list.len),
            used_cmp,
            used_ctx
        );
    $else
        var $branchless = $Typeof(used_cmp) == TypeNotSet
            &&& ($Typeof((*list)[0])::kind == SIGNED_INT
                ||| $Typeof((*list)[0])::kind == UNSIGNED_INT);
        var slice = (*list)[..];
        pdqsort_with{$Typeof(*list), $Typeof(used_cmp), $Typeof(used_ctx)}(
            slice,
            $branchless,
            log2(slice.len),
            used_cmp,
            used_ctx
        );
    $endif
}

module std::sort <Type, CmpFn, Context> @private;

const int INSERTION_SORT_THRESHOLD     = 24;
const int NINTER_THRESHOLD             = 128;
const int PARTIAL_INSERTION_SORT_LIMIT = 8;
const int BLOCK_SIZE                   = 64;
const int CACHELINE_SIZE               = 64;

struct PartitionResult @private
{
    ElementType* ptr;
    bool flag;
}

macro bool pdq_less(CmpFn cmp, Context ctx, ElementType a, ElementType b)
{
    var $has_cmp = $Typeof(cmp) != sort::TypeNotSet;
    var $has_ctx = $Typeof(ctx) != sort::TypeNotSet;
    var $by_value = $has_cmp &&& $defined($Typefrom(CmpFn::params[0].type) v = a);
    $switch:
        $case $by_value && $has_ctx:
            return cmp(a, b, ctx) < 0;
        $case $by_value:
            return cmp(a, b) < 0;
        $case $has_cmp && $has_ctx:
            return cmp(&a, &b, ctx) < 0;
        $case $has_cmp:
            return cmp(&a, &b) < 0;
        $default:
            return less(a, b);
    $endswitch
}

macro void pdq_swap_elem(ElementType* a, ElementType* b)
{
    ElementType tmp = *a;
    *a = *b;
    *b = tmp;
}

macro void pdq_sort2(ElementType* a, ElementType* b, CmpFn cmp, Context ctx)
{
    ElementType va = *a;
    ElementType vb = *b;
    bool cond      = pdq_less(cmp, ctx, vb, va);
    *a = cond ? vb : va;
    *b = cond ? va : vb;
}

macro void pdq_sort3(ElementType* a, ElementType* b, ElementType* c, CmpFn cmp, Context ctx)
{
    pdq_sort2(a, b, cmp, ctx);
    pdq_sort2(b, c, cmp, ctx);
    pdq_sort2(a, b, cmp, ctx);
}

fn void* pdq_align_cacheline(void* p) @inline
{
    uptr addr = (uptr)p;
    addr = (addr + CACHELINE_SIZE - 1) & ~(CACHELINE_SIZE - 1);
    return (void*)addr;
}

<*
 @require num <= BLOCK_SIZE : "Offset buffers hold at most BLOCK_SIZE entries"
*>
fn void pdq_swap_offsets(
    ElementType* first,
    ElementType* last,
    char* offset_l,
    char* offset_r,
    usz num,
    bool use_swaps
) @inline
{
    if (use_swaps)
    {
        for (usz i = 0; i < num; i++)
        {
            ElementType* l = first + (usz)offset_l[i];
            ElementType* r = last - (sz)offset_r[i];

            ElementType tmp = *l;
            *l = *r;
            *r = tmp;
        }
    }
    else if (num > 0)
    {
        ElementType* l = first + (usz)offset_l[0];
        ElementType* r = last - (sz)offset_r[0];

        ElementType tmp = *l;
        *l = *r;

        for (usz i = 1; i < num; i++)
        {
            l = first + (usz)offset_l[i];
            *r = *l;

            r = last - (sz)offset_r[i];
            *l = *r;
        }

        *r = tmp;
    }
}

fn void pdq_insertion_sort(ElementType[] data, CmpFn cmp, Context ctx) @inline
{
    ElementType* begin = data.ptr;
    ElementType* end   = begin + data.len;
    if (begin == end) return;

    for (ElementType* current = begin + 1; current < end; current++)
    {
        if (pdq_less(cmp, ctx, *current, *(current - 1)))
        {
            ElementType key   = *current;
            ElementType* hole = current;

            do
            {
                *hole = *(hole - 1);
                hole--;
            } while (hole > begin && pdq_less(cmp, ctx, key, *(hole - 1)));

            *hole = key;
        }
    }
}

fn void pdq_unguarded_insertion_sort(ElementType[] data, CmpFn cmp, Context ctx) @inline
{
    ElementType* begin = data.ptr;
    ElementType* end   = begin + data.len;
    if (begin == end) return;

    for (ElementType* current = begin + 1; current < end; current++)
    {
        if (pdq_less(cmp, ctx, *current, *(current - 1)))
        {
            ElementType key   = *current;
            ElementType* hole = current;

            do
            {
                *hole = *(hole - 1);
                hole--;
            } while (pdq_less(cmp, ctx, key, *(hole - 1)));

            *hole = key;
        }
    }
}

fn bool pdq_partial_insertion_sort(ElementType[] data, CmpFn cmp, Context ctx) @inline
{
    ElementType* begin = data.ptr;
    ElementType* end   = begin + data.len;
    if (begin == end) return true;

    usz limit = 0;

    for (ElementType* current = begin + 1; current < end; current++)
    {
        if (pdq_less(cmp, ctx, *current, *(current - 1)))
        {
            if (limit > PARTIAL_INSERTION_SORT_LIMIT) return false;

            ElementType key   = *current;
            ElementType* hole = current;

            do
            {
                *hole = *(hole - 1);
                hole--;
            } while (hole > begin && pdq_less(cmp, ctx, key, *(hole - 1)));

            *hole = key;
            limit += (usz)(current - hole);
        }
    }

    return true;
}

fn void pdq_sift_down(ElementType* begin, usz root, usz end, CmpFn cmp, Context ctx) @inline
{
    while (root < end / 2)
    {
        usz child = root * 2 + 1;

        if (child + 1 < end && pdq_less(cmp, ctx, begin[child], begin[child + 1]))
        {
            child++;
        }

        if (!pdq_less(cmp, ctx, begin[root], begin[child]))
        {
            return;
        }

        ElementType tmp = begin[root];
        begin[root] = begin[child];
        begin[child] = tmp;

        root = child;
    }
}

fn void pdq_heap_sort(ElementType[] data, CmpFn cmp, Context ctx)
{
    ElementType* begin = data.ptr;
    usz n              = data.len;

    if (n < 2) return;

    usz start = n / 2;
    while (start > 0)
    {
        start--;
        pdq_sift_down(begin, start, n, cmp, ctx);
    }

    usz end = n;
    while (end > 1)
    {
        end--;
        ElementType tmp = begin[0];
        begin[0] = begin[end];
        begin[end] = tmp;

        pdq_sift_down(begin, 0, end, cmp, ctx);
    }
}

fn void pdq_break_patterns(ElementType[] data) @inline
{
    ElementType* p = data.ptr;
    usz n          = data.len;

    if (n < 8) return;

    usz mid = n / 2;
    pdq_swap_elem(p, p + n / 4);
    pdq_swap_elem(p + mid, p + (n * 3) / 4);
    pdq_swap_elem(p + (n - 1), p + mid);
}

<*
 @require value.len >= INSERTION_SORT_THRESHOLD : "Partitioning is only valid past the insertion sort threshold"
 @require !pdq_less(cmp, ctx, value[value.len - 1], value[0]) : "Last element must not be smaller than the pivot (sentinel for the unguarded scan)"
*>
fn PartitionResult partition_right_branchless(ElementType[] value, CmpFn cmp, Context ctx) @inline
{
    ElementType* begin = value.ptr;
    ElementType* end   = begin + value.len;

    ElementType pivot  = *begin;
    ElementType* first = begin;
    ElementType* last  = end;

    while (pdq_less(cmp, ctx, *(++first), pivot))
    {
    }

    if (first - 1 == begin)
    {
        while (first < last && !pdq_less(cmp, ctx, *(--last), pivot))
        {
        }
    }
    else
    {
        while (!pdq_less(cmp, ctx, *(--last), pivot))
        {
        }
    }

    bool already_partitioned = first >= last;

    if (!already_partitioned)
    {
        pdq_swap_elem(first, last);
        first++;

        char[BLOCK_SIZE + CACHELINE_SIZE] offsets_l_storage;
        char[BLOCK_SIZE + CACHELINE_SIZE] offsets_r_storage;

        char* offsets_l = (char*)pdq_align_cacheline(&offsets_l_storage);
        char* offsets_r = (char*)pdq_align_cacheline(&offsets_r_storage);

        ElementType* offset_l_base = first;
        ElementType* offset_r_base = last;

        usz num_l   = 0;
        usz num_r   = 0;
        usz start_l = 0;
        usz start_r = 0;

        while (first < last)
        {
            usz num_unknown = (usz)(last - first);
            usz left_split  = num_l == 0 ? (num_r == 0 ? num_unknown / 2 : num_unknown) : 0;
            usz right_split = num_r == 0 ? num_unknown - left_split : 0;

            if (left_split >= BLOCK_SIZE)
            {
                for (char i = 0; i < BLOCK_SIZE;)
                {
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                    offsets_l[num_l] = i++;
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                }
            }
            else
            {
                for (usz i = 0; i < left_split;)
                {
                    offsets_l[num_l] = (char)(i++);
                    num_l += (usz)(!pdq_less(cmp, ctx, *first, pivot));
                    first++;
                }
            }

            if (right_split >= BLOCK_SIZE)
            {
                for (char i = 0; i < BLOCK_SIZE;)
                {
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                    offsets_r[num_r] = ++i;
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                }
            }
            else
            {
                for (usz i = 0; i < right_split;)
                {
                    offsets_r[num_r] = (char)(++i);
                    last--;
                    num_r += (usz)pdq_less(cmp, ctx, *last, pivot);
                }
            }

            usz num = num_l < num_r ? num_l : num_r;

            pdq_swap_offsets(
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

            if (num_l == 0)
            {
                start_l = 0;
                offset_l_base = first;
            }

            if (num_r == 0)
            {
                start_r = 0;
                offset_r_base = last;
            }
        }

        if (num_l > 0)
        {
            offsets_l += (sz)start_l;
            while (num_l > 0)
            {
                num_l--;
                last--;
                ElementType* l   = offset_l_base + (usz)offsets_l[num_l];
                ElementType ltmp = *l;
                *l = *last;
                *last = ltmp;
            }
            first = last;
        }

        if (num_r > 0)
        {
            offsets_r += (sz)start_r;
            while (num_r > 0)
            {
                num_r--;
                ElementType* r   = offset_r_base - (sz)offsets_r[num_r];
                ElementType rtmp = *r;
                *r = *first;
                *first = rtmp;
                first++;
            }
            last = first;
        }
    }

    ElementType* pivot_pos = first - 1;
    *begin = *pivot_pos;
    *pivot_pos = pivot;

    return { pivot_pos, already_partitioned };
}

<*
 @require value.len >= INSERTION_SORT_THRESHOLD : "Partitioning is only valid past the insertion sort threshold"
 @require !pdq_less(cmp, ctx, value[value.len - 1], value[0]) : "Last element must not be smaller than the pivot (sentinel for the unguarded scan)"
*>
fn PartitionResult partition_right(ElementType[] value, CmpFn cmp, Context ctx) @inline
{
    ElementType* begin = value.ptr;
    ElementType* end   = begin + value.len;

    ElementType pivot  = *begin;
    ElementType* first = begin;
    ElementType* last  = end;

    while (pdq_less(cmp, ctx, *(++first), pivot))
    {
    }

    if (first - 1 == begin)
    {
        while (first < last && !pdq_less(cmp, ctx, *(--last), pivot))
        {
        }
    }
    else
    {
        while (!pdq_less(cmp, ctx, *(--last), pivot))
        {
        }
    }

    bool already_partitioned = first >= last;

    while (first < last)
    {
        pdq_swap_elem(first, last);
        while (pdq_less(cmp, ctx, *(++first), pivot))
        {
        }
        while (!pdq_less(cmp, ctx, *(--last), pivot))
        {
        }
    }

    ElementType* pivot_pos = first - 1;
    *begin = *pivot_pos;
    *pivot_pos = pivot;

    return { pivot_pos, already_partitioned };
}

<*
 @require value.len >= INSERTION_SORT_THRESHOLD : "Only called past the insertion sort threshold"
*>
fn ElementType* partition_left(ElementType[] value, CmpFn cmp, Context ctx) @inline
{
    ElementType* begin = value.ptr;
    ElementType* end   = begin + value.len;

    ElementType pivot  = *begin;
    ElementType* first = begin;
    ElementType* last  = end;

    while (pdq_less(cmp, ctx, pivot, *(--last)))
    {
    }

    if (last + 1 == end)
    {
        while (first < last && !pdq_less(cmp, ctx, pivot, *(++first)))
        {
        }
    }
    else
    {
        while (!pdq_less(cmp, ctx, pivot, *(++first)))
        {
        }
    }

    while (first < last)
    {
        pdq_swap_elem(first, last);
        while (pdq_less(cmp, ctx, pivot, *(--last)))
        {
        }
        while (!pdq_less(cmp, ctx, pivot, *(++first)))
        {
        }
    }

    ElementType* pivot_pos = last;
    *begin = *pivot_pos;
    *pivot_pos = pivot;

    return pivot_pos;
}

fn void pdqsort_loop(
    ElementType[] value,
    int bad_allowed,
    bool leftmost,
    bool branchless,
    CmpFn cmp,
    Context ctx
)
{
    ElementType* begin = value.ptr;
    ElementType* end   = begin + value.len;

    while (true)
    {
        usz size = (usz)(end - begin);

        if (size < INSERTION_SORT_THRESHOLD)
        {
            if (leftmost)
            {
                pdq_insertion_sort(begin[0:size], cmp, ctx);
            }
            else
            {
                pdq_unguarded_insertion_sort(begin[0:size], cmp, ctx);
            }
            return;
        }

        usz s2 = size / 2;

        if (size > NINTER_THRESHOLD)
        {
            pdq_sort3(begin, begin + s2, end - 1, cmp, ctx);
            pdq_sort3(begin + 1, begin + (s2 - 1), end - 2, cmp, ctx);
            pdq_sort3(begin + 2, begin + (s2 + 1), end - 3, cmp, ctx);
            pdq_sort3(begin + (s2 - 1), begin + s2, begin + (s2 + 1), cmp, ctx);
            pdq_swap_elem(begin, begin + s2);
        }
        else
        {
            pdq_sort3(begin + s2, begin, end - 1, cmp, ctx);
        }

        if (!leftmost && !pdq_less(cmp, ctx, *(begin - 1), *begin))
        {
            begin = partition_left(begin[0:size], cmp, ctx) + 1;
            continue;
        }

        PartitionResult part_result = branchless ? partition_right_branchless(
            begin[0:size],
            cmp,
            ctx
        )
            : partition_right(begin[0:size], cmp, ctx);

        ElementType* pivot_pos   = part_result.ptr;
        bool already_partitioned = part_result.flag;

        usz l_size = (usz)(pivot_pos - begin);
        usz r_size = (usz)(end - (pivot_pos + 1));

        bool highly_unbalanced = l_size < size / 8 || r_size < size / 8;

        if (highly_unbalanced)
        {
            bad_allowed--;

            if (bad_allowed <= 0)
            {
                pdq_heap_sort(begin[0:size], cmp, ctx);
                return;
            }

            if (l_size >= INSERTION_SORT_THRESHOLD)
            {
                pdq_swap_elem(begin, begin + l_size / 4);
                pdq_swap_elem(pivot_pos - 1, pivot_pos - (sz)(l_size / 4));

                if (l_size > NINTER_THRESHOLD)
                {
                    pdq_swap_elem(begin + 1, begin + (l_size / 4 + 1));
                    pdq_swap_elem(begin + 2, begin + (l_size / 4 + 2));
                    pdq_swap_elem(pivot_pos - 2, pivot_pos - (sz)(l_size / 4 + 1));
                    pdq_swap_elem(pivot_pos - 3, pivot_pos - (sz)(l_size / 4 + 2));
                }
            }

            if (r_size >= INSERTION_SORT_THRESHOLD)
            {
                pdq_swap_elem(pivot_pos + 1, pivot_pos + (1 + r_size / 4));
                pdq_swap_elem(end - 1, end - (sz)(r_size / 4));

                if (r_size > NINTER_THRESHOLD)
                {
                    pdq_swap_elem(pivot_pos + 2, pivot_pos + (2 + r_size / 4));
                    pdq_swap_elem(pivot_pos + 3, pivot_pos + (3 + r_size / 4));
                    pdq_swap_elem(end - 2, end - (sz)(1 + r_size / 4));
                    pdq_swap_elem(end - 3, end - (sz)(2 + r_size / 4));
                }
            }
        }
        else
        {
            if (already_partitioned && pdq_partial_insertion_sort(
                begin[0:l_size],
                cmp,
                ctx
            ) && pdq_partial_insertion_sort((pivot_pos + 1)[0:r_size], cmp, ctx))
            {
                return;
            }
        }

        pdqsort_loop(begin[0:l_size], bad_allowed, leftmost, branchless, cmp, ctx);

        begin = pivot_pos + 1;
        leftmost = false;
    }
}

fn void pdqsort_with(ElementType[] value, bool branchless, int bad_allowed, CmpFn cmp, Context ctx)
{
    if (value.len < 2) return;
    pdqsort_loop(value, bad_allowed, true, branchless, cmp, ctx);
}
