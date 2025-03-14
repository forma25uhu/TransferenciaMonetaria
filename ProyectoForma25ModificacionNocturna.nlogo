globals [numTrans DineroA DineroB Convertidos NumRojos NumAzules NumVerdes NumAmarillos]

breed [As A]
breed [Bs B]
turtles-own [Dinero vx vy]

to setup
  ca
  ask patches [ set pcolor white ]

  set numTrans 0
  set Convertidos 0

  create-As NumA [
    setxy random-xcor random-ycor
    set color blue
    set Dinero random 101
    set shape "person"
    set size 3
    set vx Velocidad
    set vy Velocidad
  ]

  create-Bs NumB [
    setxy random-xcor random-ycor
    set color red
    set Dinero 0
    set shape "person"
    set size 3
    set vx Velocidad
    set vy Velocidad
  ]

  set NumVerdes (NumA * ProbVerde / 100)
  set NumAmarillos (NumB * ProbAmarillo / 100)

  set NumRojos (NumB - NumAmarillos)
  set NumAzules (NumA - NumVerdes)

  ask n-of NumVerdes As [ set color green ]
  ask n-of NumAmarillos Bs [ set color yellow ]

  ; Resetear gráficos
  clear-all-plots
end

to go
 ask turtles [
    mover
    ;calcular-interaccion
  ]
  ifelse TipoChoque = "SingleAgent" [
    calcular-interaccion
  ] [
    calcular-interaccion-mejorada
  ]
  ;check-collision
  manage-collision
  actualizar-dinero
end

to calcular-interaccion
  let fx 0
  let fy 0

  ask turtles [
    let agente-cercano one-of other turtles in-radius 5
     if agente-cercano != nobody [
    let x [xcor] of self
    let y [ycor] of self
    let dist sqrt (x * x + y * y + 0.1)  ;; Pequeño ajuste para evitar división entre 0

    let diferencia-dinero [Dinero] of agente-cercano - Dinero

    ;; Si la otra tortuga tiene más dinero, la atrae; si tiene menos, la repele
    let factor-choque (probabilidad-choque - 0.5) * 2  ; Rango: -1 (repulsión) a 1 (atracción)

    let fuerza-base (diferencia-dinero / 100) / (dist * dist)  ;; Fuerza proporcional a la diferencia de dinero e inversa a la distancia
    let fuerza (ifelse-value
      factor-choque = (-1) [ (- (abs fuerza-base) ) ]  ; Repulsión total
      factor-choque = 1 [ abs fuerza-base ]   ; Atracción total
      [ fuerza-base * factor-choque ]               ; Caso intermedio
    )

    set fx fx + (x * fuerza)
    set fy fy + (y * fuerza)

  ;; Normalizar el vector resultante
  let magnitude sqrt (fx * fx + fy * fy)
  if magnitude > 0 [
    set vx (fx / magnitude) * 0.5 * Velocidad  ;; Ajuste de velocidad
    set vy (fy / magnitude) * 0.5 * Velocidad
  ]
    ]
  ]
end


to calcular-interaccion-mejorada
  ask turtles [
    let fx 0  ; Fuerza total en x
    let fy 0  ; Fuerza total en y

    ; Consideramos todas las tortugas cercanas, no solo una
    let agentes-cercanos other turtles in-radius 5
    if any? agentes-cercanos [
      foreach sort agentes-cercanos [ agente ->
        ; Distancia relativa al agente cercano
        let x ([xcor] of agente - xcor)
        let y ([ycor] of agente - ycor)
        let dist sqrt (x * x + y * y + 0.01)  ;; Pequeño ajuste para evitar división entre 0

        ; Diferencia de dinero
        let diferencia-dinero ([Dinero] of agente - Dinero)

        ; Factor de atracción/repulsión
        let factor-choque (probabilidad-choque - 0.5) * 2  ; Rango: -1 (repulsión) a 1 (atracción)

        ; Fuerza base proporcional a la diferencia de dinero e inversa al cuadrado de la distancia
        let fuerza-base (diferencia-dinero / 100) / (dist * dist) * 10; Factor De Fuerza 10
        let fuerza (ifelse-value
          factor-choque = (-1) [ (- (abs fuerza-base) ) ]  ; Repulsión total
          factor-choque = 1 [ abs fuerza-base ]   ; Atracción total
          [ fuerza-base ]               ; Caso intermedio
        )
        ;print(word "fuerza base: " fuerza-base)
        ;print(word "fuerza: " fuerza)
        ;print(fuerza)
        ; Acumular la contribución de este agente a las fuerzas totales
        set fx fx + (x * fuerza)
        set fy fy + (y * fuerza)
      ]
    ]

    ; Normalizar el vector resultante
    let magnitude sqrt (fx * fx + fy * fy)
    if magnitude > 0 [
      set vx (fx / magnitude) * 0.5 * Velocidad  ; Velocidad ajustada en x
      set vy (fy / magnitude) * 0.5 * Velocidad  ; Velocidad ajustada en y
    ]
  ]
end


to mover
  ;; Aplicar movimiento en la dirección calculada
  setxy xcor + vx ycor + vy
end

to check-collision
  ask turtles [
    let vecinas other turtles in-radius 1
    if any? vecinas [
      set numTrans numTrans + 1
      handle-collision vecinas
    ]
  ]
end

to-report eliminar-elementos-repetidos [ lista1 lista2 ]
  report filter [ i -> not member? i lista2 ] lista1
end

; Algoritmo de detección de clusters
to-report detectar-clusters
  let clusters []
  ;let agentes turtles  ; Orden: AG1, AG2, AG3, AG4, AG5

  ask turtles [
    let yo self ; AG2
    let vecinos (other turtles in-radius 1) ; AG1 AG3 AG5
    let lista-vecinos [self] of vecinos
    ; [AG1 AG2 AG3]
    foreach clusters [
        cluster ->
        if member? self cluster [
            set lista-vecinos eliminar-elementos-repetidos lista-vecinos cluster
        ]
    ]

    set lista-vecinos (lput yo lista-vecinos)

    let sizeVecinos (length lista-vecinos)

    if sizeVecinos > 1 [
      set clusters lput lista-vecinos clusters
    ]
  ]
  report clusters
end

to manage-collision

    let clusters detectar-clusters

    let NumColisiones (length clusters)
    ;print(clusters)

    set NumTrans (NumTrans + NumColisiones)

    if NumColisiones > 0 [
        foreach clusters [ cl ->

          let yo last cl
          let resto but-last cl
          ask yo [
              handle-collision resto
        ]
      ]
  ]
end





to handle-collision [vecinas]
  let otro one-of vecinas  ; Selecciona una tortuga con la que choca

  ; 1. A choca con A → Equilibrar dinero
  if (breed = As and [breed] of otro = As) [
    let total (Dinero + [Dinero] of otro) / 2
    set Dinero total
    ask otro [ set Dinero total ]
  ]

  ; 2. A (verde, Dinero ≥10) choca con B (amarillo) → Transferencia total
  if (breed = As and color = green and Dinero >= 10 and
      [breed] of otro = Bs and [color] of otro = yellow) [
    ask otro [ set Dinero (Dinero + [Dinero] of myself) ]
    set Dinero 0
  ]

  ; 3. B choca con B → Equilibrar dinero
  if (breed = Bs and [breed] of otro = Bs) [
    let total ((Dinero + [Dinero] of otro) / 2)
    set Dinero total
    ask otro [ set Dinero total ]
  ]

  ; 4. A (azul) choca con B (rojo) → Quita 1 de dinero a B y A lo recibe
  if (breed = As and color = green and [breed] of otro = Bs and [color] of otro = red) [
    ask otro [
      ifelse Dinero > 0
      [
        set Dinero (Dinero - 1)
        ask myself [ set Dinero (Dinero + 1) ]  ; A recibe el dinero
      ]
      [ if Aniquilacion [become-A] ]
    ]
  ]
end

to become-A  ; Convierte un B a A azul si su dinero llega a 0
  set breed As
  set color blue
  set shape "person"
  set Dinero 1  ; Ahora inicia con 5 en vez de 0 para evitar estancamiento
  set Convertidos (Convertidos + 1)
  set NumRojos (NumRojos - 1)
  set NumAzules (NumAzules + 1)
  set-current-plot "Poblaciones"
  set-current-plot-pen "Rojos"
  plot NumRojos
  set-current-plot-pen "Azules"
  plot NumAzules
  ;plot NumVerdes
  ;plot NumAmarillos
end

to actualizar-dinero
  set DineroA sum [Dinero] of As
  set DineroB sum [Dinero] of Bs
  set-current-plot "Dinero"
  set-current-plot-pen "A"
  plot DineroA
  set-current-plot-pen "B"
  plot DineroB
end

@#$#@#$#@
GRAPHICS-WINDOW
373
10
989
627
-1
-1
6.02
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
30.0

SLIDER
54
179
226
212
ProbAmarillo
ProbAmarillo
0
100
22.0
1
1
NIL
HORIZONTAL

SLIDER
54
212
226
245
ProbVerde
ProbVerde
0
100
55.0
1
1
NIL
HORIZONTAL

BUTTON
54
29
117
62
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
117
30
180
63
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1102
41
1302
191
Dinero
Tiempo
Dinero
0.0
10.0
0.0
10.0
true
true
"" "plot DineroA"
PENS
"A" 1.0 0 -14070903 true "plot DineroA" "plot DineroA"
"B" 1.0 0 -5298144 true "" "plot DineroB"

MONITOR
1102
193
1182
238
Convertidos
Convertidos
17
1
11

MONITOR
1183
193
1253
238
Colisiones
numTrans
17
1
11

SWITCH
54
245
177
278
Aniquilacion
Aniquilacion
0
1
-1000

SLIDER
54
277
226
310
Velocidad
Velocidad
0
20
1.5
0.5
1
NIL
HORIZONTAL

SLIDER
54
310
226
343
probabilidad-choque
probabilidad-choque
0
1
0.0
0.1
1
NIL
HORIZONTAL

PLOT
1098
238
1298
388
Poblaciones
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Rojos" 1.0 0 -2674135 true "" "plot NumRojos"
"Azules" 1.0 0 -14070903 true "" "plot NumAzules"

INPUTBOX
54
60
209
120
NumA
200.0
1
0
Number

INPUTBOX
54
119
209
179
NumB
100.0
1
0
Number

CHOOSER
53
344
191
389
TipoChoque
TipoChoque
"SingleAgent" "MultiAgent"
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
