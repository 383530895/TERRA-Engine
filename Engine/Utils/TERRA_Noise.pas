Unit TERRA_Noise;
{$I terra.inc}
//http://www.gamedev.net/community/forums/mod/journal/journal.asp?jn=339903&reply_id=3089065

Interface

Uses TERRA_Utils, TERRA_Image, TERRA_Vector3D;

Const
  GradientTableSize = 256;
  CellGridSize = 32;

Type
  NoiseGenerator = Class(TERRAObject)
    Public
      Procedure Release; Override;

      Function Noise(X,Y,Z:Single; RX,RY,RZ:Integer):Single; Virtual; Abstract;
      Function CreateImage(Width, Height:Integer):Image; Virtual; Abstract;
    End;

  PerlinNoiseGenerator = Class(NoiseGenerator)
    Protected
      _Gradients:Array[0..Pred(GradientTableSize*3)] Of Single;

      Procedure InitGradients;

      Function Permutate(x: Integer): Integer;
      Function Index(ix, iy, iz: Integer): Integer;
      Function Lattice(ix, iy, iz: Integer; fx, fy, fz: Single): Single;
      Function Lerp(t, x0, x1: Single): Single;
      Function Smooth(x: Single): Single;

    Public
      Constructor Create;
      
      Function Noise(X,Y,Z:Single; RX,RY,RZ:Integer):Single; Override;

      Function CreateImage(Width, Height:Integer):Image; Override;
    End;

  CellNoiseGenerator = Class(NoiseGenerator)
    Protected
      _Points:Array Of Array Of Array Of Vector3D;

    Public
      Constructor Create;
      Function Noise(X,Y,Z:Single; RX,RY,RZ:Integer):Single; Override;

      Function CreateImage(Width, Height:Integer):Image; Override;
    End;

Implementation
Uses TERRA_Color, TERRA_OS, TERRA_Math;

{ NoiseGenerator }
Procedure NoiseGenerator.Release;
Begin
  // do nothing
End;

{ PerlinNoiseGenerator }
Procedure PerlinNoiseGenerator.InitGradients;
Var
  I:Integer;
  Z,R,Theta: Single;
Begin
  // Generate random gradient vectors.
  For I:=0 to Pred(GradientTableSize) Do
  Begin
    z := 1 - 2*Random;
    r := sqrt(1 - z*z);
    theta := 2*PI*Random;
    _Gradients[i*3] := r*cos(theta);
    _Gradients[i*3 + 1] := r*sin(theta);
    _Gradients[i*3 + 2] := z;
  End;
End;

Const
  { Borrowed from Darwyn Peachey (see references above).
    The gradient table is indexed with an XYZ triplet, which is first turned
    into a single random index using a lookup in this table. The table simply
    contains all numbers in [0..255] in random order. }
  PERM: array [0..Pred(GradientTableSize)] of Byte = (
      225,155,210,108,175,199,221,144,203,116, 70,213, 69,158, 33,252,
        5, 82,173,133,222,139,174, 27,  9, 71, 90,246, 75,130, 91,191,
      169,138,  2,151,194,235, 81,  7, 25,113,228,159,205,253,134,142,
      248, 65,224,217, 22,121,229, 63, 89,103, 96,104,156, 17,201,129,
       36,  8,165,110,237,117,231, 56,132,211,152, 20,181,111,239,218,
      170,163, 51,172,157, 47, 80,212,176,250, 87, 49, 99,242,136,189,
      162,115, 44, 43,124, 94,150, 16,141,247, 32, 10,198,223,255, 72,
       53,131, 84, 57,220,197, 58, 50,208, 11,241, 28,  3,192, 62,202,
       18,215,153, 24, 76, 41, 15,179, 39, 46, 55,  6,128,167, 23,188,
      106, 34,187,140,164, 73,112,182,244,195,227, 13, 35, 77,196,185,
       26,200,226,119, 31,123,168,125,249, 68,183,230,177,135,160,180,
       12,  1,243,148,102,166, 38,238,251, 37,240,126, 64, 74,161, 40,
      184,149,171,178,101, 66, 29, 59,146, 61,254,107, 42, 86,154,  4,
      236,232,120, 21,233,209, 45, 98,193,114, 78, 19,206, 14,118,127,
       48, 79,147, 85, 30,207,219, 54, 88,234,190,122, 95, 67,143,109,
      137,214,145, 93, 92,100,245,  0,216,186, 60, 83,105, 97,204, 52
    );

Constructor PerlinNoiseGenerator.Create;
Begin
  // Initialize the random gradients before we start.
  InitGradients;
End;

Function PerlinNoiseGenerator.Permutate(x:Integer):Integer;
Const
  MASK = Pred(GradientTableSize);
Begin
  // Do a lookup in the permutation table.
  Result := PERM[x and MASK];
End;

Function PerlinNoiseGenerator.Index(ix, iy, iz: Integer): Integer;
Begin
  // Turn an XYZ triplet into a single gradient table index.
  Result := Permutate(ix + Permutate(iy + Permutate(iz)));
End;

Function PerlinNoiseGenerator.Lattice(ix, iy, iz: Integer; fx, fy, fz: Single): Single; {$IFDEF FPC} Inline; {$ENDIF}
Var
  g:Integer;
Begin
  // Look up a random gradient at [ix,iy,iz] and dot it with the [fx,fy,fz] vector.
  g := Index(ix, iy, iz)*3;
  Result := _Gradients[g]*fx + _Gradients[g+1]*fy + _Gradients[g+2]*fz;
End;

Function PerlinNoiseGenerator.Lerp(t, x0, x1: Single): Single; {$IFDEF FPC} Inline; {$ENDIF}
Begin
  // Simple linear interpolation.
  Result := x0 + t*(x1-x0);
End;

Function PerlinNoiseGenerator.Smooth(x: Single): Single; {$IFDEF FPC} Inline; {$ENDIF}
Begin
  { Smoothing curve. This is used to calculate interpolants so that the noise
    doesn't look blocky when the frequency is low. }
  Result := x*x*(3 - 2*x);
End;

Function PerlinNoiseGenerator.Noise(x, y, z: Single; RX,RY,RZ:Integer): Single;
Var
  ix, iy, iz: Integer;
  fx0, fx1, fy0, fy1, fz0, fz1: Single;
  wx, wy, wz: Single;
  vx0, vx1, vy0, vy1, vz0, vz1: Single;
Begin
  { The main noise function. Looks up the pseudorandom gradients at the nearest
    lattice points, dots them with the input vector, and interpolates the
    results to produce a single output value in [0, 1] range. }

  ix := Floor(x);
  fx0 := x - ix;
  fx1 := fx0 - 1;
  wx := Smooth(fx0);
  iy := Floor(y);
  fy0 := y - iy;
  fy1 := fy0 - 1;
  wy := Smooth(fy0);

  iz := Floor(z);
  fz0 := z - iz;
  fz1 := fz0 - 1;
  wz := Smooth(fz0);

  vx0 := Lattice(ix, iy, iz, fx0, fy0, fz0);
  vx1 := Lattice((ix+1) Mod RX, iy, iz, fx1, fy0, fz0);
  vy0 := Lerp(wx, vx0, vx1);

  vx0 := Lattice(ix, (iy+1) Mod RX, iz, fx0, fy1, fz0);
  vx1 := Lattice((ix+1) Mod RX, (iy+1) Mod RY, iz, fx1, fy1, fz0);
  vy1 := Lerp(wx, vx0, vx1);

  vz0 := Lerp(wy, vy0, vy1);

  vx0 := Lattice(ix, iy, (iz+1) Mod RZ, fx0, fy0, fz1);
  vx1 := Lattice((ix+1) Mod RX, iy, (iz+1) Mod RZ, fx1, fy0, fz1);
  vy0 := Lerp(wx, vx0, vx1);

  vx0 := Lattice(ix, (iy+1) Mod RY, (iz+1) Mod RZ, fx0, fy1, fz1);
  vx1 := Lattice((ix+1) Mod RX, (iy+1) Mod RY, (iz+1) MOD RZ, fx1, fy1, fz1);
  vy1 := Lerp(wx, vx0, vx1);

  vz1 := Lerp(wy, vy0, vy1);

  Result := Lerp(wz, vz0, vz1);
End;


Function PerlinNoiseGenerator.CreateImage(Width, Height:Integer):Image;
Var
  I,J,K:Integer;
  X,Y,Z:Single;
  Freq,M:Single;
  NF:Array[1..4] Of Single;
  P:Color;
Begin
  Result := Image.Create(Width, Height);
  Z:=0;

  For J:=0 To Pred(Height) Do
    For I:= 0 To Pred(Width) do
    Begin
      X := I;
      Y := J;

      // Take various octaves of noise and add them.
      Freq := 2;
      M := 8.0;
      For K:=1 To 4 Do
      Begin
        nf[K] :=(Self.Noise(x/Freq, y/Freq, z, Width Div Trunc(Freq), Height Div Trunc(Freq), 1)/M);
        Freq := Freq * 2.0;
        M := M * 0.5;
      End;

      P.R := Round(255 * (nf[1]+1) * 0.5);
      P.G := Round(255 * (nf[2]+1) * 0.5);
      P.B := Round(255 * (nf[3]+1) * 0.5);
      P.A := Round(255 * (nf[4]+1) * 0.5);

      // Write the result to the texture image.
      Result.SetPixel(I,J, P);
    End;
    //Result.Save('noise.png');
End;


Constructor CellNoiseGenerator.Create;
Var
  I,J,K:Integer;
Begin
  RandSeed := GetTime;
  SetLength(_Points, CellGridSize, CellGridSize, CellGridSize);
  For K:=0 To Pred(CellGridSize) Do
    For J:=0 To Pred(CellGridSize) Do
      For I:=0 To Pred(CellGridSize) Do
      Begin
        _Points[I,J,K] := VectorCreate(RandomFloat, RandomFloat, RandomFloat);
      End;
End;

Function CellNoiseGenerator.Noise(X,Y,Z:Single; RX,RY,RZ:Integer):Single;
Var
  TX,TY,TZ:Integer;
  CX,CY,CZ:Integer;
  SX,SY,SZ:Single;
  P:Vector3D;
  I,J,K:Integer;
  Dist,R:Single;
  N:Integer;
Begin
  N := CellGridSize Div Rz;
  SX := (RX/N);
  SY := (RY/N);
  SZ := (RX/N);

  TX := Trunc(X/SX);
  TY := Trunc(Y/SY);
  TZ := Trunc(Z/SZ);

  Dist:=999;
  For K:=-1 To 1 Do
    For J:=-1 To 1 Do
      For I:=-1 To 1 Do
      Begin
        CX := (Word(TX+I) Mod N);
        CY := (Word(TY+J) Mod N);
        CZ := (Word(TZ+K) Mod N);

        P := VectorMultiply(_Points[CX,CY,CZ], VectorCreate(SX,SY,SZ));

        CX := (TX+I);
        CY := (TY+J);
        CZ := (TZ+K);

        P := VectorAdd(P, VectorCreate(CX*SX, CY*SY, CZ*SZ));
        R := P.Distance(VectorCreate(X,Y,Z));
        If (R<Dist) Then
          Dist := R;
      End;

    R := SX;
    If (SY>R) Then R := SY;
    If (SZ>R) Then R := SZ;
    R := R * 2;
    Dist := Dist / R;
    Result := Dist;
End;

Function CellNoiseGenerator.CreateImage(Width, Height:Integer):Image;
Var
  I,J,K:Integer;
  X,Y,Z:Single;
  M:Single;
  NF:Array[1..4] Of Single;
  P:Color;
Begin
  Result := Image.Create(Width, Height);
  Z:=0;

  For J:=0 To Pred(Height) Do
    For I:= 0 To Pred(Width) do
    Begin
      X := I;
      Y := J;

      // Take various octaves of noise and add them.
      M := 4.0;
      For K:=1 To 4 Do
      Begin
        nf[K] := (Self.Noise(x, y, z, Trunc(Width), Trunc(Height), K)/M);
        M := M * 0.5;
      End;

      P.R := Round(255 * (nf[1]+1) * 0.25);
      P.G := Round(255 * (nf[2]+1) * 0.25);
      P.B := Round(255 * (nf[3]+1) * 0.25);
      P.A := Round(255 * (nf[4]+1) * 0.25);

      // Write the result to the texture image.
      Result.SetPixel(I,J, P);
    End;
End;

End.

