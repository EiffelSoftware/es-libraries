The integration of Gobo Eiffel into the EiffelStudio delivery required a few changes:

See the diff with the branch 26.09 of the Gobo Eiffel project (https://github.com/gobo-eiffel/gobo.git)

diff --git a/Src/contrib/library/gobo/library/kernel/src/library.ecf b/Src/contrib/library/gobo/library/kernel/src/library.ecf
index 3d613b96ac0..265ea48fcf9 100644
--- a/Src/contrib/library/gobo/library/kernel/src/library.ecf
+++ b/Src/contrib/library/gobo/library/kernel/src/library.ecf
@@ -21,6 +21,7 @@
 			<exclude>/EIFGENs$</exclude>
 		</file_rule>
 		<variable name="GOBO_LIBRARY" value="../../.."/>
+		<assembly name="eiffelsoftware_runtime" location="$ISE_EIFFEL\studio\spec\$ISE_PLATFORM\lib\$ISE_DOTNET_PLATFORM\EiffelSoftware.Runtime.dll"/>
 		<library name="free_elks" location="${GOBO_LIBRARY}/library/free_elks/library_${GOBO_EIFFEL}.ecf" readonly="true"/>
 		<library name="time" location="${ISE_LIBRARY}/library/time/time.ecf" readonly="true">
 			<condition>
diff --git a/Src/contrib/library/gobo/library/math/src/decimal/ma_decimal.e b/Src/contrib/library/gobo/library/math/src/decimal/ma_decimal.e
index c654ac2a6f4..239e52f9e17 100644
--- a/Src/contrib/library/gobo/library/math/src/decimal/ma_decimal.e
+++ b/Src/contrib/library/gobo/library/math/src/decimal/ma_decimal.e
@@ -16,9 +16,9 @@ inherit
 		rename
 			plus as binary_plus alias "+",
 			minus as binary_minus alias "-",
-			product as product alias "*",
-			quotient as quotient alias "/",
-			opposite as opposite alias "-"
+			product as product alias "*" alias "×",
+			quotient as quotient alias "/" alias "÷",
+			opposite as opposite alias "-" alias "−"
 		redefine
 			out,
 			is_equal,
@@ -622,7 +622,7 @@ feature -- Status report
 
 feature -- Basic operations
 
-	product alias "*" (other: like Current): like Current
+	product alias "*" alias "×" (other: like Current): like Current
 			-- Product by `other'
 		do
 			Result := multiply (other, shared_decimal_context)
@@ -646,7 +646,7 @@ feature -- Basic operations
 			sum_not_void: Result /= Void
 		end
 
-	opposite alias "-": like Current
+	opposite alias "-" alias "−": like Current
 			-- Unary minus
 		do
 			Result := minus (shared_decimal_context)
@@ -662,7 +662,7 @@ feature -- Basic operations
 			subtract_not_void: Result /= Void
 		end
 
-	quotient alias "/" (other: like Current): like Current
+	quotient alias "/" alias "÷" (other: like Current): like Current
 			-- Division by `other'
 		do
 			Result := divide (other, shared_decimal_context)
