" Vim regex fallback for .scene/.scenex/.ktree files; tree-sitter highlighting
" supersedes it. The groups link to the same captures
" queries/scenex/highlights.scm uses, so both paths render identically. See that
" file for the role scheme.
if exists('b:current_syntax')
  finish
endif

setlocal iskeyword+=-

" Top-level introducers
syntax keyword sceneKeyword import ns distrib ktree kgraph scene inst comp
syntax keyword sceneKeyword similar obj ws agn set
syntax keyword sceneModifier extrinsic

" Slot names: sub-block openers and field keys
syntax keyword sceneSlot joints inertia actuation limits mimic polarity
syntax keyword sceneSlot parent child root tip joint multiplier gear ratio
syntax keyword sceneSlot command-interface state-interface mass inertia-matrix
syntax keyword sceneSlot wrt xyz xyzw angles axes unit orientation
syntax keyword sceneSlot dimension lower upper mean std-dev covariance
syntax keyword sceneSlot resolution fov update-rate observes type name count
syntax keyword sceneSlot module attr pkg path sys py base

" The kind of thing being declared
syntax keyword sceneType object workspace agent model body frame pose
syntax keyword sceneType camera force-torque imu fixed revolute serial parallel
syntax keyword sceneType uniform normal uniform-rotation
syntax keyword sceneType quat euler direction-cosine urdf mjcf usd

" Closed-vocabulary values
syntax keyword sceneConstant PositivePolarity NegativePolarity
syntax keyword sceneConstant position velocity torque current acceleration effort
syntax keyword sceneConstant rgb depth rgbd force angular-velocity linear-acceleration
syntax keyword sceneConstant xyz xzy yxz yzx zxy zyx

" Words that relate two things
syntax keyword sceneOperator of to as map sample tree

" <path> cross-references
syntax region sceneRef start=/</ end=/>/ oneline
  \ contains=sceneRefPath,sceneRefDot
syntax match sceneRefPath /[A-Za-z_][A-Za-z0-9_-]*/ contained
syntax match sceneRefDot /\./ contained

" The axis slicing a frame reference: `<body.frame>.z`
syntax match sceneAxis /\(>\s*\.\)\@<=[xyz]\>/

" Declared names: the identifier following its kind
syntax match sceneDeclName
  \ /\<\(object\|workspace\|agent\|body\|frame\|pose\|model\|camera\|force-torque\|imu\|fixed\|revolute\)\s\+\zs[A-Za-z_][A-Za-z0-9_-]*/
syntax match sceneDeclName /)\s*\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*\({\|of\>\)/
syntax match sceneDeclName /\<ktree\s\+\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*{/
syntax match sceneDeclName /\<ns\s\+\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*=/

syntax match sceneNumber /\<[-+]\?\(\d\+\(\.\d*\)\?\|\.\d\+\)\([eE][-+]\?\d\+\)\?/
  \ nextgroup=sceneUnit skipwhite
syntax match sceneUnit /\v(kg\*m\^2|N\*m|rad\/s\^2|deg\/s\^2|rad\/s|deg\/s|mm|cm|m|rad|deg|kg|g|Hz)>/ contained

syntax region sceneString start=/"/ skip=/\\./ end=/"/ oneline
syntax region sceneString start=/'/ skip=/\\./ end=/'/ oneline
syntax match sceneComment /\/\/.*/ contains=@Spell

highlight default link sceneKeyword   @keyword
highlight default link sceneModifier  @keyword.modifier
highlight default link sceneSlot      @label
highlight default link sceneOperator  @keyword.operator
highlight default link sceneType      @type
highlight default link sceneConstant  @constant
highlight default link sceneDeclName  @variable
highlight default link sceneRef       @punctuation.special
highlight default link sceneRefPath   @variable.member
highlight default link sceneAxis      @variable.parameter
highlight default link sceneRefDot    @punctuation.delimiter
highlight default link sceneNumber    @number
highlight default link sceneUnit      @constant
highlight default link sceneString    @string
highlight default link sceneComment   @comment

let b:current_syntax = 'scenex'
