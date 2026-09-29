package fun.p3nd.wolfox;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class MainActivity extends AppCompatActivity {
    private TextView status;
    private SharedPreferences prefs;
    private static final String KEY_TARGET = "target_package";

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        setContentView(R.layout.activity_main);
        status = findViewById(R.id.status);
        prefs = getSharedPreferences("wolfox", MODE_PRIVATE);
        bind(R.id.location, "قسم الموقع يستخدم صلاحيات Android الرسمية فقط.");
        bind(R.id.camera, "اختيار الصور والكاميرا سيتم عبر واجهات Android الرسمية.");
        bind(R.id.bluetooth, "Bluetooth يعمل ضمن صلاحيات النظام.");
        findViewById(R.id.target).setOnClickListener(v -> chooseTarget());
        refreshTargetStatus();
    }

    private void bind(int id, String message) {
        ((Button)findViewById(id)).setOnClickListener(v -> status.setText(message));
    }

    private void chooseTarget() {
        PackageManager pm = getPackageManager();
        Intent query = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        List<android.content.pm.ResolveInfo> found = pm.queryIntentActivities(query, 0);
        List<android.content.pm.ResolveInfo> apps = new ArrayList<>();
        for (android.content.pm.ResolveInfo r : found) {
            if (r.activityInfo != null && !getPackageName().equals(r.activityInfo.packageName)) apps.add(r);
        }
        Collections.sort(apps, (a,b) -> a.loadLabel(pm).toString().compareToIgnoreCase(b.loadLabel(pm).toString()));
        if (apps.isEmpty()) { status.setText("لا توجد تطبيقات متاحة للاختيار."); return; }
        String[] labels = new String[apps.size()];
        for (int i=0;i<apps.size();i++) labels[i] = apps.get(i).loadLabel(pm) + "\n" + apps.get(i).activityInfo.packageName;
        new androidx.appcompat.app.AlertDialog.Builder(this)
            .setTitle("اختر التطبيق المستهدف")
            .setItems(labels, (d, which) -> {
                String pkg = apps.get(which).activityInfo.packageName;
                prefs.edit().putString(KEY_TARGET, pkg).apply();
                refreshTargetStatus();
            })
            .setNegativeButton("إلغاء", null).show();
    }

    private void refreshTargetStatus() {
        String pkg = prefs.getString(KEY_TARGET, "");
        if (pkg.isEmpty()) { status.setText("اختر التطبيق المستهدف."); return; }
        try {
            ApplicationInfo info = getPackageManager().getApplicationInfo(pkg, 0);
            status.setText("التطبيق المستهدف: " + getPackageManager().getApplicationLabel(info) + "\n" + pkg);
        } catch (PackageManager.NameNotFoundException e) {
            prefs.edit().remove(KEY_TARGET).apply();
            status.setText("التطبيق المستهدف لم يعد مثبتًا.");
        }
    }
}