" Vim regex fallback for .robmot files; tree-sitter highlighting supersedes it.
" The groups link to the same captures queries/robmot/highlights.scm uses, so
" both paths render identically. See that file for the role scheme.
if exists('b:current_syntax')
  finish
endif

setlocal iskeyword+=-

" Top-level introducers
syntax keyword motionSpecKeyword import ns exec-context tolerances ros
syntax keyword motionSpecKeyword guarded-motion constraint-handler
syntax keyword motionSpecModifier any all extrinsic
syntax match   motionSpecModifier /@disable/

" Slot names: sub-block openers and field keys
syntax keyword motionSpecSlot context description world pre spec post
syntax keyword motionSpecSlot when while until handles runs-in
syntax keyword motionSpecSlot monitors controllers solvers satisfied violated
syntax keyword motionSpecSlot publishers subscribers action-clients action-servers
syntax keyword motionSpecSlot type name platform config timestep runs-scene
syntax keyword motionSpecSlot agent algorithm configuration quantity gravity
syntax keyword motionSpecSlot constraint measured-derivative measured-velocity
syntax keyword motionSpecSlot output-saturation integral-saturation
syntax keyword motionSpecSlot max lower upper mass damping stiffness
syntax keyword motionSpecSlot max-velocity max-acceleration max-jerk shape
syntax keyword motionSpecSlot start end goal center axes angles xyzw
syntax keyword motionSpecSlot pitch revolutions amplitude anchor radius
syntax keyword motionSpecSlot plane-normal form on-goal on-end
syntax keyword motionSpecSlot of wrt ref-point as-seen-by joint ft-sensor
syntax keyword motionSpecSlot Kp Ki Kd decay

" The kind of thing being declared
syntax keyword motionSpecType pose position orientation velocity-twist wrench
syntax keyword motionSpecType acceleration-twist angular-velocity linear-velocity
syntax keyword motionSpecType linear-acceleration angular-acceleration linear-jerk
syntax keyword motionSpecType force torque direction free-vector joint-position
syntax keyword motionSpecType distance angle dimensionless duration path-parameter
syntax keyword motionSpecType linear-distance angular-distance path
syntax keyword motionSpecType velocity-profile admittance profile
syntax keyword motionSpecType pid impedance feed-forward
syntax keyword motionSpecType serial-chain mobile-platform command-forwarding
syntax keyword motionSpecType real-world simulation
syntax keyword motionSpecType lerp circle arc helix figure8
syntax keyword motionSpecType euler quat direction-cosine

" Closed-vocabulary values
syntax keyword motionSpecConstant achd rne trapezoidal s-curve gerono bernoulli
syntax keyword motionSpecConstant velocity-composition velocity-distribution
syntax keyword motionSpecConstant force-composition force-distribution
syntax keyword motionSpecConstant KinovaGen3 KinovaGen3-2F85 Robotiq2F85 RobotiqFT300s
syntax keyword motionSpecConstant succeeded aborted canceled
syntax keyword motionSpecConstant xyz xzy yxz yzx zxy zyx

" Relation, view and action words
syntax keyword motionSpecOperator keeping equal to greater more less than is
syntax keyword motionSpecOperator larger smaller up away from between outside
syntax keyword motionSpecOperator and within distance elapsed progress moving
syntax keyword motionSpecOperator along at on in by snapshot rotated using
syntax keyword motionSpecOperator as via apply for realized produce detect monitor
syntax keyword motionSpecOperator trigger hold flag publish event topic message
syntax keyword motionSpecOperator action saturation limits observes

" <path> cross-references and [path] inline overrides
syntax region motionSpecRef start=/</ end=/>/ oneline
  \ contains=motionSpecRefPath,motionSpecRefDot
syntax region motionSpecInlineRef start=/\[/ end=/\]/ oneline
  \ contains=motionSpecRefPath,motionSpecRefDot,motionSpecNumber,motionSpecUnit
syntax match motionSpecRefPath /[A-Za-z_][A-Za-z0-9_-]*/ contained
syntax match motionSpecRefDot /\./ contained

" Subspace and axis selectors trailing a reference
syntax match motionSpecSelector /\.\zs\(angacc\|angvel\|linacc\|linvel\|torque\|force\|orientation\|position\)\ze\>/
syntax match motionSpecSelector /\.\%(angacc\|angvel\|linacc\|linvel\|torque\|force\|orientation\|position\)\.\zs[xyz]\ze\>/

" Declared names: the identifier immediately before ':'
syntax match motionSpecDeclName /\<[A-Za-z_][A-Za-z0-9_-]*\ze\s*:/

syntax match motionSpecNumber /\<[-+]\?\(\d\+\(\.\d*\)\?\|\.\d\+\)\([eE][-+]\?\d\+\)\?/
  \ nextgroup=motionSpecUnit skipwhite
syntax match motionSpecUnit /\v(rad\/s\^2|deg\/s\^2|m\/s\^2|m\/s\^3|rad\/s|deg\/s|m\/s|cm\/s|mm|cm|m|rad|deg|Nm|N|ms|s)>/ contained

syntax region motionSpecString start=/"/ skip=/\\./ end=/"/ oneline
syntax match motionSpecComment /\/\/.*/ contains=@Spell

highlight default link motionSpecKeyword   @keyword
highlight default link motionSpecModifier  @keyword.modifier
highlight default link motionSpecSlot      @label
highlight default link motionSpecOperator  @keyword.operator
highlight default link motionSpecType      @type
highlight default link motionSpecConstant  @constant
highlight default link motionSpecDeclName  @variable
highlight default link motionSpecRef       @punctuation.special
highlight default link motionSpecInlineRef @punctuation.special
highlight default link motionSpecRefPath   @variable.member
highlight default link motionSpecSelector  @variable.parameter
highlight default link motionSpecRefDot    @punctuation.delimiter
highlight default link motionSpecNumber    @number
highlight default link motionSpecUnit      @constant
highlight default link motionSpecString    @string
highlight default link motionSpecComment   @comment

let b:current_syntax = 'robmot'
