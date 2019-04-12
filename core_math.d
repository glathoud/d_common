module d_glat.core_math;

public import std.math;

import d_glat.core_static;
import std.algorithm : sort;

/*
  A few mathematical tool functions.

  By Guillaume Lathoud, 2019
  glat@glat.info

  The Boost license applies to this file, as described in ./LICENSE
 */

T logsum( T )( in T[] arr )
nothrow @safe
/* Input log(data), output: log(sum(data))
 
 Addition done in a smart way to minimize precision loss.
*/
{
  pragma( inline, true );
  
  immutable n = arr.length;
  mixin(static_array_code(`buffer`, `T`, `n`));
  return logsum_nogc!T( arr, 0, n, buffer );
}

T logsum_nogc( T )( in T[] arr, in size_t i_begin, in size_t i_end
                    , T[] buffer
                    )
pure nothrow @safe @nogc
/*
 Input log(data) := arr[i_begin..i_end]

 Output: log(sum(data))
 
 Addition done in a smart sorted way to minimize precision loss.

 Some explanation can be found e.g. here 
http://www.glat.info/ma/2006-CHN-USS-TIME-DOMAIN/my_logsum_fast.pdf
*/
{
  pragma( inline, true );

  immutable n = buffer.length;

  debug assert( i_begin < i_end );
  debug assert( i_end - i_begin == n );

  buffer[] = arr[ i_begin..i_end ][];
  buffer.sort;

  immutable one = cast( T )( 1.0 );
  
  size_t step = 1;
  size_t step_pow = 0;
  
  while (step < n)
    {
      immutable next_step = step << 1;

      immutable j_end = ((n-1) >>> step_pow) << step_pow;
      
      debug assert( j_end > 0 );
      
      for (size_t j = 0; j < j_end;)
        {
          immutable j0 = j;
          
          T a = buffer[ j ];  j += step;
          T b = buffer[ j ];  j += step;
          
          buffer[ j0 ] = b + log( one + exp( a - b ) );
        }
      
      step = next_step;
      ++step_pow;
    }

  return buffer[ 0 ];
}


T median( T )( in T[] arr )
pure nothrow @safe
{
  pragma( inline, true );
  
  return median_inplace( arr.dup );
}

T median_inplace( T )( T[] arr )
  pure nothrow @safe @nogc
{
  pragma( inline, true );
  
  arr.sort;
  immutable n = arr.length;
  immutable half = cast( T )( 0.5 );

  return 1 == n % 2
    ?  arr[ $>>1 ]
    :  (arr[ $>>1 ] + arr[ ($-1)>>1 ]) * half;
}


unittest
{
  import std.stdio;
  import std.path;

  writeln;
  writeln( "unittest starts: ", baseName( __FILE__ ) );

  immutable verbose = false;
  
  import std.random;
  import std.algorithm;
  import std.range;

  {
    
    auto rnd = MinstdRand0(42);
    
    foreach (n; 1..301)
      {
        double[] data    = iota(0,n).map!(_ => uniform( cast( double )( 1.0 ), cast( double )( 100.0 ), rnd )).array;
        double[] logdata = data.map!"cast( double )( log(a) )".array;
        double   logsum  = logsum( logdata );
        immutable double logsum_expected = log( data.reduce!"a+b" );
        
        if (verbose)
          {
            writeln;
            writeln("n: ", n);
            writeln("data: ", data);
            writeln("logsum, expected: ", [logsum, logsum_expected], " delta:", logsum - logsum_expected);
          }

        assert( approxEqual( logsum, logsum_expected, 1e-8, 1e-8 ) );
      }

  }

  
  {
    assert( median( [ 1.0,2.0,3.0,4.0,5.0 ] ) == 3.0 );
    assert( median( [ 1.0,2.0,3.0,4.0,5.0,6.0 ] ) == (3.0+4.0)*0.5 );

    {
      immutable double[] arr = [ 1.0, 4.0, 5.0, 2.0, 3.0 ];
      assert( 3.0 == median( arr ) );
    }

    {
      double[] arr = [ 1.0, 4.0, 5.0, 2.0, 3.0 ];
      auto arr0 = arr.idup;
      assert( arr == arr0 );
      assert( 3.0 == median_inplace( arr ) );
      assert( arr != arr0 );
    }
  }
  
  writeln( "unittest passed: ", baseName( __FILE__ ) );
}